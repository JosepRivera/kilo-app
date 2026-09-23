import 'package:flutter/cupertino.dart';

import '../../theme/forecast_palette.dart';
import 'purchase_review_screen.dart';
import 'stock_close_review_screen.dart';

enum VoiceAction { stockClose, purchase }

// Night (after 5pm, before the ~5-6am processing cut) is the stock close; otherwise it is a purchase.
VoiceAction actionForTime(DateTime t) =>
    t.hour >= 17 || t.hour < 6 ? VoiceAction.stockClose : VoiceAction.purchase;

void openDictation(BuildContext context) => showCupertinoModalPopup<void>(
  context: context,
  builder: (_) => _DictationSheet(initial: actionForTime(DateTime.now())),
);

// ponytail: simulated listening; recording + transcription lands with the voice pipeline.
class _DictationSheet extends StatefulWidget {
  const _DictationSheet({required this.initial});

  final VoiceAction initial;

  @override
  State<_DictationSheet> createState() => _DictationSheetState();
}

class _DictationSheetState extends State<_DictationSheet> {
  late var _action = widget.initial;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final stockClose = _action == VoiceAction.stockClose;
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              CupertinoSlidingSegmentedControl<VoiceAction>(
                groupValue: _action,
                onValueChanged: (a) => setState(() => _action = a!),
                children: const {
                  VoiceAction.stockClose: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Cierre de hoy'),
                  ),
                  VoiceAction.purchase: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Compra'),
                  ),
                },
              ),
              const Spacer(),
              Icon(CupertinoIcons.mic_circle_fill, size: 88, color: p.accent),
              const SizedBox(height: 12),
              Text(
                'Te escucho',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stockClose
                    ? '¿Cuánto queda de cada insumo?'
                    : 'Qué compraste, cuánto y a cuánto',
                style: TextStyle(fontSize: 17, color: p.muted),
              ),
              const Spacer(),
              CupertinoButton(
                onPressed: () {
                  final root = Navigator.of(context, rootNavigator: true);
                  root.pop();
                  root.push(
                    CupertinoPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => stockClose
                          ? const StockCloseReviewScreen()
                          : const PurchaseReviewScreen(),
                    ),
                  );
                },
                child: Text(
                  'Listo',
                  style: TextStyle(
                    color: p.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

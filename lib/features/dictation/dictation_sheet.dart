import 'package:flutter/cupertino.dart';

import '../../theme/forecast_palette.dart';
import '../../ui/sheet.dart';
import 'purchase_review_screen.dart';
import 'stock_close_review_screen.dart';

enum VoiceAction { stockClose, purchase }

VoiceAction actionForTime(DateTime t) =>
    t.hour >= 17 || t.hour < 6 ? VoiceAction.stockClose : VoiceAction.purchase;

void openDictation(BuildContext context) => showFloatingSheet<void>(
  context,
  builder: (_) => _Dictation(initial: actionForTime(DateTime.now())),
);

class _Dictation extends StatefulWidget {
  const _Dictation({required this.initial});

  final VoiceAction initial;

  @override
  State<_Dictation> createState() => _DictationState();
}

class _DictationState extends State<_Dictation> {
  late var _action = widget.initial;

  void _done() {
    final root = Navigator.of(context, rootNavigator: true);
    root.pop();
    root.push(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _action == VoiceAction.stockClose
            ? const StockCloseReviewScreen()
            : const PurchaseReviewScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final stockClose = _action == VoiceAction.stockClose;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<VoiceAction>(
            groupValue: _action,
            onValueChanged: (a) => setState(() => _action = a!),
            children: const {
              VoiceAction.stockClose: Text('Cierre de hoy'),
              VoiceAction.purchase: Text('Compra'),
            },
          ),
        ),
        const SizedBox(height: 28),
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
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: p.accent,
            borderRadius: BorderRadius.circular(26),
            padding: const EdgeInsets.symmetric(vertical: 15),
            onPressed: _done,
            child: Text(
              'Listo',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: p.onAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

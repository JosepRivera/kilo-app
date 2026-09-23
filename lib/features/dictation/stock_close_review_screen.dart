import 'package:flutter/cupertino.dart';

import '../../data/supplies.dart';
import '../../theme/forecast_palette.dart';
import '../../ui/panel.dart';
import 'review_parts.dart';

/// One dictated line of the nightly close: how much is left of a supply.
class CloseEntry {
  const CloseEntry(
    this.name,
    this.icon,
    this.unit,
    this.remaining, {
    this.phrase,
  });

  final String name;
  final String? icon;
  final String unit;
  final double remaining;
  final String?
  phrase; // informal quantity as spoken, already converted to [unit]
}

// ponytail: simulated transcription (Doña Rosa) until the voice pipeline exists.
const _transcript =
    'Quedan cuatro kilos de pollo, trece de papa, tres de cebolla, medio balde de tomate, '
    'kilo y medio de limón y un atado de culantro.';
const _entries = [
  CloseEntry('Pollo entero', 'chicken', 'kg', 4),
  CloseEntry('Papa canchán', 'potato', 'kg', 13),
  CloseEntry('Cebolla roja', 'onion', 'kg', 3),
  CloseEntry('Tomate', 'tomato', 'kg', 5, phrase: 'medio balde'),
  CloseEntry('Limón sutil', 'lime', 'kg', 1.5),
  CloseEntry('Culantro', 'cilantro', 'atados', 1),
];

/// Fase 2 review: editable remaining stock, anomaly and mishearing checks, then save.
class StockCloseReviewScreen extends StatefulWidget {
  const StockCloseReviewScreen({super.key});

  @override
  State<StockCloseReviewScreen> createState() => _StockCloseReviewScreenState();
}

class _StockCloseReviewScreenState extends State<StockCloseReviewScreen> {
  late final _qty = {
    for (final e in _entries)
      e.name: TextEditingController(text: formatQty(e.remaining)),
  };
  final _focus = FocusNode();
  String? _chickenCheck, _potatoCheck;

  @override
  void dispose() {
    for (final c in _qty.values) {
      c.dispose();
    }
    _focus.dispose();
    super.dispose();
  }

  void _noConsumption() => showCupertinoDialog<void>(
    context: context,
    builder: (dialog) => CupertinoAlertDialog(
      title: const Text('¿Hoy no hubo consumo?'),
      content: const Text(
        'El día queda en cero y cuenta como dato real, no como olvido.',
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Cancelar'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(dialog);
            Navigator.pop(context);
          },
          child: const Text('Marcar sin consumo'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    return ReviewScaffold(
      title: 'Cierre de hoy',
      canSave: _chickenCheck != null && _potatoCheck != null,
      onSave: () => Navigator.pop(context),
      children: [
        const TranscriptPanel(_transcript),
        FlagPanel(
          icon: supplyIcon('chicken', 32),
          message: 'Según lo que dictaste, hoy se usaron 13 kg de pollo; normalmente son unos 4 kg. ¿Es correcto?',
          primary: 'Sí, es correcto',
          secondary: 'Corregir',
          resolved: _chickenCheck,
          onPrimary: () =>
              setState(() => _chickenCheck = 'Confirmaste 13 kg usados hoy'),
          onSecondary: () {
            setState(
              () => _chickenCheck = 'Corrige la cantidad de pollo abajo',
            );
            _focus.requestFocus();
          },
        ),
        FlagPanel(
          icon: supplyIcon('potato', 32),
          message: 'Escuché “trece” kilos de papa. ¿Quisiste decir “tres”?',
          primary: 'Usar 3 kg',
          secondary: 'Dejar 13 kg',
          resolved: _potatoCheck,
          onPrimary: () => setState(() {
            _qty['Papa canchán']!.text = '3';
            _potatoCheck = 'Papa corregida a 3 kg';
          }),
          onSecondary: () =>
              setState(() => _potatoCheck = 'Papa se queda en 13 kg'),
        ),
        Panel(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader(CupertinoIcons.cube_box, 'LO QUE QUEDA'),
              for (final (i, e) in _entries.indexed) ...[
                if (i > 0) const PanelDivider(),
                SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      supplyIcon(e.icon, 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: TextStyle(fontSize: 17, color: p.text),
                            ),
                            if (e.phrase != null)
                              Text(
                                '“${e.phrase}” = ${formatQty(e.remaining)} ${e.unit}',
                                style: TextStyle(fontSize: 13, color: p.muted),
                              ),
                          ],
                        ),
                      ),
                      QuantityField(
                        controller: _qty[e.name]!,
                        unit: e.unit,
                        width: 112,
                        focusNode: e.name == 'Pollo entero' ? _focus : null,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        CupertinoButton(
          onPressed: _noConsumption,
          child: Text('Hoy no hubo consumo', style: TextStyle(color: p.accent)),
        ),
      ],
    );
  }
}

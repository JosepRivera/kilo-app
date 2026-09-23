import 'package:flutter/cupertino.dart';

import '../../data/store.dart';
import '../../domain/engine.dart';
import '../../domain/models.dart';
import '../../theme/forecast_palette.dart';
import '../../ui/format.dart';
import '../../ui/panel.dart';
import 'review_parts.dart';

class StockCloseReviewScreen extends StatefulWidget {
  const StockCloseReviewScreen({super.key});

  @override
  State<StockCloseReviewScreen> createState() => _StockCloseReviewScreenState();
}

class _StockCloseReviewScreenState extends State<StockCloseReviewScreen> {
  late final KiloStore _store = KiloScope.of(context);
  late final List<SupplyInfo> _supplies = _store.closeSupplies();
  late final Map<String, TextEditingController> _qty = {
    for (final s in _supplies)
      s.id: TextEditingController(text: formatQty(_heard(s)))
        ..addListener(_edited),
  };
  late final Map<String, FocusNode> _focus = {
    for (final s in _supplies) s.id: FocusNode(),
  };
  final _confirmed = <String, double>{};
  late final String? _misheard = _pickMisheard();

  String? _pickMisheard() {
    final e = _store.engine;
    final candidates =
        _supplies.where((s) {
          final f = e.forecast(s.id, _store.today);
          return s.critical && f > 0 && e.currentStock(s.id) >= 3.6 * f;
        }).toList()..sort(
          (a, b) => (e.forecast(b.id, _store.today) * b.referencePrice)
              .compareTo(e.forecast(a.id, _store.today) * a.referencePrice),
        );
    return candidates.firstOrNull?.id;
  }

  double _heard(SupplyInfo s) {
    final e = _store.engine;
    final saved = e
        .records(s.id)
        .where((r) => r.date == _store.today && !r.isClosed)
        .firstOrNull;
    if (saved != null) return saved.remaining!;
    final expected = e.expectedRemainingTonight(s.id);
    final misheard = s.id == _misheard
        ? expected - 2.5 * e.forecast(s.id, _store.today)
        : expected;
    return roundUpToStep(misheard < 0 ? 0 : misheard, s.unit);
  }

  void _edited() => setState(() {});

  double? _value(String id) =>
      double.tryParse(_qty[id]!.text.replaceAll(',', '.'));

  Map<String, AnomalyFlag> get _flags => {
    for (final s in _supplies)
      if (_value(s.id) case final v?) s.id: ?_store.engine.checkClose(s.id, v),
  };

  @override
  void dispose() {
    for (final c in _qty.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
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
            _store.markNoConsumption();
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
    final flags = _flags;
    final pending = flags.entries
        .where((f) => _confirmed[f.key] != _value(f.key))
        .toList();
    final valid = _supplies.every((s) => _value(s.id) != null);
    final transcript =
        'Quedan ${[for (final s in _supplies) '${withUnit(_heard(s), s.unit)} de ${s.name.toLowerCase()}'].join(', ')}.';

    return ReviewScaffold(
      title: 'Cierre de hoy',
      canSave: valid && pending.isEmpty,
      onSave: () {
        _store.saveClose({for (final s in _supplies) s.id: _value(s.id)!});
        Navigator.pop(context);
      },
      children: [
        TranscriptPanel(transcript),
        for (final f in flags.entries)
          Builder(
            builder: (context) {
              final s = _store.data.supply(f.key);
              final done = _confirmed[f.key] == _value(f.key);
              return FlagPanel(
                icon: supplyIcon(s.icon, 32),
                message:
                    'Según lo que dictaste, hoy se usaron ${withUnit(double.parse(f.value.consumed.toStringAsFixed(1)), s.unit)} '
                    'de ${s.name.toLowerCase()}; normalmente son unos ${withUnit(double.parse(f.value.usual.toStringAsFixed(1)), s.unit)}. '
                    '¿Es correcto?',
                primary: 'Sí, es correcto',
                secondary: 'Corregir',
                resolved: done ? 'Confirmado' : null,
                onPrimary: () =>
                    setState(() => _confirmed[f.key] = _value(f.key)!),
                onSecondary: () => _focus[f.key]!.requestFocus(),
              );
            },
          ),
        Panel(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader(CupertinoIcons.cube_box, 'LO QUE QUEDA'),
              for (final (i, s) in _supplies.indexed) ...[
                if (i > 0) const PanelDivider(),
                SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      supplyIcon(s.icon, 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.name,
                          style: TextStyle(
                            fontSize: 17,
                            color: flags.containsKey(s.id) ? p.alert : p.text,
                          ),
                        ),
                      ),
                      QuantityField(
                        controller: _qty[s.id]!,
                        unit: s.unit,
                        width: 128,
                        focusNode: _focus[s.id],
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

import 'package:flutter/cupertino.dart';

import '../../data/store.dart';
import '../../domain/engine.dart';
import '../../domain/models.dart';
import '../../theme/forecast_palette.dart';
import '../../ui/format.dart';
import '../../ui/panel.dart';
import '../../ui/sheet.dart';
import 'review_parts.dart';

class _Line {
  _Line(this.supply, double quantity, double cost, this.expiresOn)
    : quantity = TextEditingController(text: formatQty(quantity)),
      cost = TextEditingController(text: cost.toStringAsFixed(2));

  final SupplyInfo supply;
  final TextEditingController quantity;
  final TextEditingController cost;
  final costFocus = FocusNode();
  DateTime expiresOn;

  double? get qty => double.tryParse(quantity.text.replaceAll(',', '.'));
  double? get total => double.tryParse(cost.text.replaceAll(',', '.'));
  double? get unitPrice =>
      qty == null || total == null || qty == 0 ? null : total! / qty!;
}

class PurchaseReviewScreen extends StatefulWidget {
  const PurchaseReviewScreen({super.key});

  @override
  State<PurchaseReviewScreen> createState() => _PurchaseReviewScreenState();
}

class _PurchaseReviewScreenState extends State<PurchaseReviewScreen> {
  late final KiloStore _store = KiloScope.of(context);
  late final DateTime _today = _store.today;
  late final List<_Line> _lines = _heardLines();
  final _confirmed = <String, double>{};

  List<_Line> _heardLines() {
    final e = _store.engine;
    final recs = [
      for (final s in _store.data.supplies)
        if (e.isDue(s.categoryId)) e.recommend(s.id),
    ].where((r) => r.toBuy > 0).toList();
    final ticked = recs.where((r) => _store.isBought(r.supply.id)).toList();
    return [
      for (final r in ticked.isEmpty ? recs : ticked)
        _Line(
            r.supply,
            r.toBuy,
            r.toBuy *
                r.supply.referencePrice *
                (r.supply.id == 'onion' ? 1.6 : 1.0),
            DateTime(
              _today.year,
              _today.month,
              _today.day + r.supply.shelfLifeDays,
            ),
          )
          ..quantity.addListener(_edited)
          ..cost.addListener(_edited),
    ];
  }

  void _edited() => setState(() {});

  @override
  void dispose() {
    for (final l in _lines) {
      l.quantity.dispose();
      l.cost.dispose();
      l.costFocus.dispose();
    }
    super.dispose();
  }

  Future<void> _pickExpiry(_Line line) => showFloatingSheet<void>(
    context,
    title: 'Fecha de vencimiento',
    builder: (_) => SizedBox(
      height: 216,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: line.expiresOn,
        minimumDate: _today,
        onDateTimeChanged: (d) => setState(() => line.expiresOn = day(d)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final flags = <_Line, PriceFlag>{
      for (final l in _lines)
        if (l.unitPrice case final u?)
          l: ?_store.engine.checkPrice(l.supply.id, u),
    };
    final pending = flags.keys
        .where((l) => _confirmed[l.supply.id] != l.unitPrice)
        .toList();
    final valid = _lines.every(
      (l) => l.qty != null && l.qty! > 0 && l.total != null,
    );
    final total = _lines.fold(0.0, (t, l) => t + (l.total ?? 0));
    final transcript =
        'Compré ${[for (final l in _lines) '${withUnit(l.qty ?? 0, l.supply.unit)} de ${l.supply.name.toLowerCase()} a ${money(l.total ?? 0)}'].join(', ')}.';

    return ReviewScaffold(
      title: 'Compra',
      canSave: _lines.isNotEmpty && valid && pending.isEmpty,
      onSave: () {
        _store.savePurchase([
          for (final l in _lines)
            PurchaseLine(l.supply.id, l.qty!, l.total!, l.expiresOn),
        ]);
        Navigator.pop(context);
      },
      children: [
        if (_lines.isEmpty)
          Panel(
            child: Text(
              'Hoy no hay nada por comprar.',
              style: TextStyle(fontSize: 17, color: p.muted),
            ),
          )
        else
          TranscriptPanel(transcript),
        for (final f in flags.entries)
          FlagPanel(
            icon: supplyIcon(f.key.supply.icon, 32),
            message:
                '${f.key.supply.name} salió a ${money(f.value.unitPrice)} por ${_singular(f.key.supply.unit)}; '
                'normalmente lo pagas a ${money(f.value.usual)}. ¿Es correcto?',
            primary: 'Sí, es correcto',
            secondary: 'Corregir',
            resolved: _confirmed[f.key.supply.id] == f.key.unitPrice
                ? 'Precio confirmado'
                : null,
            onPrimary: () =>
                setState(() => _confirmed[f.key.supply.id] = f.key.unitPrice!),
            onSecondary: () => f.key.costFocus.requestFocus(),
          ),
        if (_lines.isNotEmpty)
          Panel(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelHeader(
                  CupertinoIcons.cube_box,
                  'LOTES QUE SE CREAN',
                ),
                for (final (i, l) in _lines.indexed) ...[
                  if (i > 0) const PanelDivider(),
                  _LotRow(
                    line: l,
                    today: _today,
                    onExpiry: () => _pickExpiry(l),
                  ),
                ],
              ],
            ),
          ),
        if (_lines.isNotEmpty)
          Panel(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(fontSize: 17, color: p.muted),
                  ),
                ),
                Text(
                  money(total),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: p.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _singular(String unit) => withUnit(1, unit).substring(2);

class _LotRow extends StatelessWidget {
  const _LotRow({
    required this.line,
    required this.today,
    required this.onExpiry,
  });

  final _Line line;
  final DateTime today;
  final VoidCallback onExpiry;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final d = line.expiresOn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              supplyIcon(line.supply.icon, 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  line.supply.name,
                  style: TextStyle(fontSize: 17, color: p.text),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(128, 44),
                color: p.background,
                borderRadius: BorderRadius.circular(10),
                onPressed: onExpiry,
                child: Text(
                  'vence ${weekdayShort[d.weekday - 1].toLowerCase()} ${d.day}',
                  style: TextStyle(fontSize: 15, color: p.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 44),
              Expanded(
                child: QuantityField(
                  controller: line.quantity,
                  unit: line.supply.unit,
                  width: double.infinity,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuantityField(
                  controller: line.cost,
                  unit: 'soles',
                  width: double.infinity,
                  focusNode: line.costFocus,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

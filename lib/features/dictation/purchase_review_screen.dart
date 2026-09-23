import 'package:flutter/cupertino.dart';

import '../../data/supplies.dart';
import '../../theme/forecast_palette.dart';
import '../../ui/panel.dart';
import 'review_parts.dart';

class LotDraft {
  LotDraft(
    this.name,
    this.icon,
    this.unit,
    this.quantity,
    this.cost,
    this.expires,
  );

  final String name;
  final String? icon;
  final String unit;
  final double quantity, cost;
  DateTime expires;

  double get unitPrice => cost / quantity;
}

const _transcript =
    'Compré veintisiete kilos de pollo a doscientos cuarenta y tres soles, dieciocho de papa a treinta '
    'y seis, diez de cebolla a cuarenta y dos, y seis kilos de limón a treinta.';
const _limeMatches = ['Limón sutil', 'Limón tahití', 'Lima persa'];

class PurchaseReviewScreen extends StatefulWidget {
  const PurchaseReviewScreen({super.key});

  @override
  State<PurchaseReviewScreen> createState() => _PurchaseReviewScreenState();
}

class _PurchaseReviewScreenState extends State<PurchaseReviewScreen> {
  static final _today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  final _lots = [
    LotDraft(
      'Pollo entero',
      'chicken',
      'kg',
      27,
      243,
      _today.add(const Duration(days: 3)),
    ),
    LotDraft(
      'Papa canchán',
      'potato',
      'kg',
      18,
      36,
      _today.add(const Duration(days: 14)),
    ),
    LotDraft(
      'Cebolla roja',
      'onion',
      'kg',
      10,
      42,
      _today.add(const Duration(days: 20)),
    ),
  ];
  String? _lime, _onionCheck;

  double get _total => _lots.fold(0.0, (t, l) => t + l.cost);

  void _resolveLime(String name) => setState(() {
    _lime = name;
    _lots.add(
      LotDraft(name, 'lime', 'kg', 6, 30, _today.add(const Duration(days: 7))),
    );
  });

  Future<void> _pickExpiry(LotDraft lot) => showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Container(
      height: 280,
      color: ForecastPalette.of(context).surface,
      child: SafeArea(
        top: false,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: lot.expires,
          minimumDate: _today,
          onDateTimeChanged: (d) => setState(() => lot.expires = d),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final onion = _lots.firstWhere((l) => l.name == 'Cebolla roja');

    return ReviewScaffold(
      title: 'Compra',
      canSave: _lime != null && _onionCheck != null,
      onSave: () => Navigator.pop(context),
      children: [
        const TranscriptPanel(_transcript),
        Panel(
          color: _lime == null ? p.alertBackground : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  supplyIcon('lime', 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _lime == null
                          ? 'Escuché “limón”. ¿Cuál es?'
                          : 'Limón: $_lime',
                      style: TextStyle(fontSize: 17, color: p.text),
                    ),
                  ),
                ],
              ),
              if (_lime == null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _limeMatches)
                      CupertinoButton(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        onPressed: () => _resolveLime(m),
                        child: Text(
                          m,
                          style: TextStyle(fontSize: 15, color: p.text),
                        ),
                      ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      onPressed: () => _resolveLime('Limón (nuevo)'),
                      child: Text(
                        '+ Crear nuevo',
                        style: TextStyle(fontSize: 15, color: p.accent),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        FlagPanel(
          icon: supplyIcon('onion', 32),
          message:
              'La cebolla salió a S/ ${onion.unitPrice.toStringAsFixed(2)} el kilo; '
              'normalmente la pagas a S/ 2.60. ¿Es correcto?',
          primary: 'Sí, es correcto',
          secondary: 'Corregir',
          resolved: _onionCheck,
          onPrimary: () => setState(() => _onionCheck = 'Precio confirmado'),
          onSecondary: () =>
              setState(() => _onionCheck = 'Corrige el costo abajo'),
        ),
        Panel(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader(CupertinoIcons.cube_box, 'LOTES QUE SE CREAN'),
              for (final (i, l) in _lots.indexed) ...[
                if (i > 0) const PanelDivider(),
                _LotRow(lot: l, onExpiry: () => _pickExpiry(l)),
              ],
            ],
          ),
        ),
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
                'S/ ${_total.toStringAsFixed(2)}',
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

class _LotRow extends StatelessWidget {
  const _LotRow({required this.lot, required this.onExpiry});

  final LotDraft lot;
  final VoidCallback onExpiry;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final numbers = TextStyle(
      fontSize: 15,
      color: p.muted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          supplyIcon(lot.icon, 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lot.name, style: TextStyle(fontSize: 17, color: p.text)),
                Text(
                  '${withUnit(lot.quantity, lot.unit)} · S/ ${lot.cost.toStringAsFixed(2)}',
                  style: numbers,
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(128, 44),
            color: p.background,
            borderRadius: BorderRadius.circular(10),
            onPressed: onExpiry,
            child: Text(
              'vence ${_date(lot.expires)}',
              style: TextStyle(fontSize: 15, color: p.accent),
            ),
          ),
        ],
      ),
    );
  }
}

String _date(DateTime d) =>
    '${const ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'][d.weekday - 1]} ${d.day}';

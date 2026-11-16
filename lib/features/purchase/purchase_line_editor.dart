import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/widgets/amount_field.dart';
import 'purchase_review_view_model.dart';

class PurchaseLineEditor extends StatelessWidget {
  const PurchaseLineEditor({
    super.key,
    required this.viewModel,
    required this.lineId,
  });

  static const _maxExpiryDays = 3650;

  final PurchaseReviewViewModel viewModel;
  final int lineId;

  Future<void> _pickExpiry(BuildContext context, DateTime current) async {
    final today = viewModel.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(today) ? today : current,
      firstDate: today,
      lastDate: today.add(const Duration(days: _maxExpiryDays)),
    );
    if (picked != null) {
      viewModel.setExpiry(
        lineId,
        DateTime.utc(picked.year, picked.month, picked.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final line = viewModel.lineById(lineId);
            final supply = line?.supply;
            if (line == null || supply == null) return const SizedBox.shrink();
            final expiresOn = line.expiresOn ?? viewModel.today;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        supply.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Listo'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AmountField(
                  label: 'Cantidad',
                  value: line.quantity,
                  suffix: supply.unit,
                  autofocus: line.quantity == null,
                  onChanged: (value) => viewModel.setQuantity(lineId, value),
                ),
                const SizedBox(height: 12),
                AmountField(
                  label: 'Precio total',
                  value: line.cost,
                  prefix: 'S/ ',
                  onChanged: (value) => viewModel.setCost(lineId, value),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vence'),
                  trailing: Text(
                    '${shortDate(expiresOn)} ${expiresOn.year}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: () => _pickExpiry(context, expiresOn),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

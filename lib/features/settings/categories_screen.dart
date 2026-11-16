import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/show_message.dart';
import '../../core/widgets/text_prompt_dialog.dart';
import '../../data/models/supply_category.dart';
import 'category_card.dart';
import 'settings_snapshot.dart';
import 'settings_view_model.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  Future<void> _report(BuildContext context, Future<String?> change) async {
    final error = await change;
    if (error != null && context.mounted) showMessage(context, error);
  }

  Future<void> _editSpend(BuildContext context, SupplyCategory category) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => TextPromptDialog(
        title: category.name,
        label: 'Gasto al mes en soles',
        initialText: editableAmount(category.monthlySpend),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
    final soles = text == null ? null : parseAmount(text);
    if (soles == null || soles < 0 || !context.mounted) return;
    await _report(context, viewModel.setMonthlySpend(category, soles));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compras y gasto por categoría')),
      body: AsyncView<SettingsSnapshot>(
        source: viewModel,
        builder: (context, snapshot) => ListView.builder(
          padding: const EdgeInsets.only(bottom: 32),
          itemCount: snapshot.categories.length,
          itemBuilder: (context, index) {
            final category = snapshot.categories[index];
            return CategoryCard(
              category: category,
              onInterval: (days) {
                HapticFeedback.selectionClick();
                _report(context, viewModel.setPurchaseInterval(category, days));
              },
              onEditSpend: () => _editSpend(context, category),
            );
          },
        ),
      ),
    );
  }
}

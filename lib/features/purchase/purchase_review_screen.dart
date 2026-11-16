import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/show_message.dart';
import '../../data/models/supply.dart';
import '../catalog/ambiguous_item_tile.dart';
import '../catalog/catalog_sheets.dart';
import '../catalog/transcript_card.dart';
import '../catalog/unknown_item_tile.dart';
import 'measure_question_tile.dart';
import 'purchase_line_draft.dart';
import 'purchase_line_editor.dart';
import 'purchase_line_tile.dart';
import 'purchase_review_view_model.dart';

class PurchaseReviewScreen extends StatelessWidget {
  const PurchaseReviewScreen({
    super.key,
    required this.viewModel,
    required this.catalog,
  });

  final PurchaseReviewViewModel viewModel;
  final CatalogSheets catalog;

  Future<void> _report(BuildContext context, Future<String?> action) async {
    final error = await action;
    if (error != null && context.mounted) showMessage(context, error);
  }

  Future<void> _exit(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (!viewModel.hasUnsavedEdits) {
      navigator.pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar compra?'),
        content: const Text('Lo que registraste aquí no se guardará.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar compra'),
          ),
        ],
      ),
    );
    if (discard == true) navigator.pop();
  }

  Future<void> _save(BuildContext context) async {
    final error = await viewModel.save();
    if (!context.mounted) return;
    if (error != null) return showMessage(context, error);
    Navigator.of(context).pop('Compra guardada.');
  }

  void _edit(BuildContext context, PurchaseLineDraft line) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PurchaseLineEditor(viewModel: viewModel, lineId: line.id),
    );
  }

  Future<void> _create(BuildContext context, PurchaseLineDraft line) async {
    final supply = await catalog.create(
      context,
      spoken: line.spoken,
      categories: viewModel.categories,
    );
    if (supply == null || !context.mounted) return;
    await _report(context, viewModel.createSupply(line.id, supply));
  }

  Future<void> _add(BuildContext context) async {
    final pick = await catalog.search(
      context,
      categories: viewModel.categories,
    );
    if (pick == null || !context.mounted) return;
    final candidate = pick.candidate;
    final error = await (candidate != null
        ? viewModel.addCandidate(candidate)
        : viewModel.addNew(pick.newSupply!));
    if (!context.mounted) return;
    if (error != null) return showMessage(context, error);
    _edit(context, viewModel.lines.last);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => PopScope(
        canPop: !viewModel.hasUnsavedEdits,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _exit(context);
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => _exit(context),
              tooltip: 'Cancelar',
              icon: const Icon(Icons.close),
            ),
            title: const Text('Compra'),
            actions: [
              TextButton(
                onPressed: viewModel.canSave ? () => _save(context) : null,
                child: const Text('Confirmar'),
              ),
            ],
          ),
          body: AsyncView<List<Supply>>(
            source: viewModel,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: _sections(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, PurchaseLineDraft line) {
    final busy = viewModel.isBusy;
    if (line.supply == null && line.isUnknown) {
      return UnknownItemTile(
        spoken: line.spoken,
        onCreate: busy ? null : () => _create(context, line),
        onRemove: busy ? null : () => viewModel.remove(line.id),
      );
    }
    if (line.supply == null) {
      return AmbiguousItemTile(
        spoken: line.spoken,
        candidates: line.candidates,
        onPick: busy
            ? null
            : (candidate) =>
                  _report(context, viewModel.pickCandidate(line.id, candidate)),
      );
    }
    if (line.asksMeasure) {
      return MeasureQuestionTile(
        line: line,
        onAnswer: (amount) => viewModel.answerMeasure(line.id, amount),
      );
    }
    return PurchaseLineTile(
      line: line,
      problem: viewModel.problemOf(line),
      priceFlag: viewModel.priceFlagOf(line),
      onEdit: () => _edit(context, line),
      onConfirmPrice: () => viewModel.confirmPrice(line.id),
      onRemove: () => viewModel.remove(line.id),
    );
  }

  List<Widget> _sections(BuildContext context) {
    final theme = Theme.of(context);
    final transcript = viewModel.transcript;
    final lines = viewModel.lines;
    final addTile = ListTile(
      leading: const Icon(Icons.add),
      title: const Text('Agregar insumo'),
      onTap: viewModel.isBusy ? null : () => _add(context),
    );
    return [
      if (viewModel.isBusy) const LinearProgressIndicator(),
      if (transcript != null && transcript.isNotEmpty)
        TranscriptCard(transcript: transcript),
      SectionCard(
        header: const Text('Lo que compraste'),
        children: [
          if (lines.isEmpty)
            const EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Aún no hay nada',
              message: 'Agrega cada insumo con su cantidad y precio.',
            ),
          for (final line in lines)
            KeyedSubtree(key: ValueKey(line.id), child: _line(context, line)),
          addTile,
        ],
      ),
      if (lines.isNotEmpty)
        SectionCard(
          children: [
            ListTile(
              title: Text(
                'Total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Text(
                money(viewModel.total),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
    ];
  }
}

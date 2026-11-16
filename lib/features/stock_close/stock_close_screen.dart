import 'package:material_ui/material_ui.dart';

import '../../core/widgets/async_view.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/show_message.dart';
import '../../data/models/supply.dart';
import '../catalog/ambiguous_item_tile.dart';
import '../catalog/catalog_sheets.dart';
import '../catalog/pending_item.dart';
import '../catalog/transcript_card.dart';
import '../catalog/unknown_item_tile.dart';
import 'close_entry_tile.dart';
import 'close_exit_choice.dart';
import 'close_exit_dialog.dart';
import 'resume_banner.dart';
import 'stock_close_view_model.dart';
import 'no_consumption_dialog.dart';

class StockCloseScreen extends StatelessWidget {
  const StockCloseScreen({
    super.key,
    required this.viewModel,
    required this.catalog,
  });

  final StockCloseViewModel viewModel;
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
    final choice = await showDialog<CloseExitChoice>(
      context: context,
      builder: (_) => const CloseExitDialog(),
    );
    if (choice == null) return;
    if (choice == CloseExitChoice.discard) await viewModel.discard();
    navigator.pop();
  }

  Future<void> _save(BuildContext context) async {
    final error = await viewModel.save();
    if (!context.mounted) return;
    if (error != null) return showMessage(context, error);
    Navigator.of(context).pop('Cierre guardado.');
  }

  Future<void> _noConsumption(BuildContext context) async {
    final confirmed = await NoConsumptionDialog.confirm(context);
    if (!confirmed || !context.mounted) return;
    final error = await viewModel.markNoConsumption();
    if (!context.mounted) return;
    if (error != null) return showMessage(context, error);
    Navigator.of(context).pop('Hoy quedó sin consumo.');
  }

  Future<void> _add(BuildContext context) async {
    final pick = await catalog.search(
      context,
      categories: viewModel.categories,
    );
    if (pick == null || !context.mounted) return;
    final candidate = pick.candidate;
    await _report(
      context,
      candidate != null
          ? viewModel.addCandidate(candidate)
          : viewModel.addNew(pick.newSupply!),
    );
  }

  Future<void> _create(BuildContext context, PendingItem item) async {
    final supply = await catalog.create(
      context,
      spoken: item.spoken,
      categories: viewModel.categories,
    );
    if (supply == null || !context.mounted) return;
    await _report(context, viewModel.createSupply(item, supply));
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
            title: const Text('Cierre de hoy'),
            actions: [
              TextButton(
                onPressed: viewModel.canSave ? () => _save(context) : null,
                child: const Text('Guardar'),
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

  List<Widget> _sections(BuildContext context) {
    final busy = viewModel.isBusy;
    final transcript = viewModel.transcript;
    final entries = viewModel.entries;
    final addTile = ListTile(
      leading: const Icon(Icons.add),
      title: const Text('Agregar insumo'),
      onTap: busy ? null : () => _add(context),
    );
    return [
      if (busy) const LinearProgressIndicator(),
      if (viewModel.resumedFromDraft)
        SectionCard(
          children: [ResumeBanner(onRestart: busy ? null : viewModel.restart)],
        ),
      if (transcript != null && transcript.isNotEmpty)
        TranscriptCard(transcript: transcript),
      if (viewModel.pending.isNotEmpty)
        SectionCard(
          header: const Text('Por resolver'),
          children: [
            for (final item in viewModel.pending)
              item.isUnknown
                  ? UnknownItemTile(
                      spoken: item.spoken,
                      onCreate: busy ? null : () => _create(context, item),
                      onRemove: busy
                          ? null
                          : () => viewModel.removePending(item),
                    )
                  : AmbiguousItemTile(
                      spoken: item.spoken,
                      candidates: item.candidates,
                      onPick: busy
                          ? null
                          : (candidate) => _report(
                              context,
                              viewModel.pickCandidate(item, candidate),
                            ),
                    ),
          ],
        ),
      if (entries.isEmpty)
        SectionCard(
          children: [
            const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No hay insumos por cerrar',
              message: 'Agrega lo que tienes ahora para empezar a contar.',
            ),
            addTile,
          ],
        )
      else
        SectionCard(
          header: const Text('Lo que queda'),
          children: [
            for (final entry in entries)
              CloseEntryTile(
                key: ValueKey(entry.supply.id),
                entry: entry,
                flag: viewModel.flagOf(entry),
                onChanged: (value) =>
                    viewModel.setRemaining(entry.supply.id, value),
                onConfirmFlag: () => viewModel.confirmFlag(entry.supply.id),
                onAcceptSuggestion: () =>
                    viewModel.acceptSuggestion(entry.supply.id),
                onKeepHeard: () => viewModel.keepHeard(entry.supply.id),
              ),
            addTile,
          ],
        ),
      SectionCard(
        children: [
          ListTile(
            leading: const Icon(Icons.event_busy_outlined),
            title: const Text('Hoy no hubo consumo'),
            onTap: busy ? null : () => _noConsumption(context),
          ),
        ],
      ),
    ];
  }
}

import 'package:material_ui/material_ui.dart';

import '../core/widgets/show_message.dart';
import '../core/widgets/view_model_host.dart';
import '../data/models/supply.dart';
import '../data/models/voice_draft.dart';
import '../data/models/voice_kind.dart';
import '../features/catalog/catalog_sheets.dart';
import '../features/dictation/dictation_result.dart';
import '../features/dictation/dictation_sheet.dart';
import '../features/dictation/dictation_view_model.dart';
import '../features/purchase/purchase_review_screen.dart';
import '../features/purchase/purchase_review_view_model.dart';
import '../features/settings/categories_screen.dart';
import '../features/settings/recording_mode_screen.dart';
import '../features/settings/recording_mode_view_model.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/settings_view_model.dart';
import '../features/stock_close/stock_close_screen.dart';
import '../features/stock_close/stock_close_view_model.dart';
import '../features/supplies/supply_detail_screen.dart';
import '../features/supplies/supply_detail_view_model.dart';
import '../features/today/why_buy_sheet.dart';
import 'app_dependencies.dart';

class AppNavigator {
  AppNavigator(this._deps) : _catalog = CatalogSheets(_deps.supplies);

  final AppDependencies _deps;
  final CatalogSheets _catalog;

  Future<void> openSettings(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ViewModelHost(
        create: () => SettingsViewModel(
          restaurants: _deps.restaurants,
          records: _deps.records,
          revision: _deps.revision,
        )..load(),
        builder: (_, viewModel) => SettingsScreen(
          viewModel: viewModel,
          onOpenCategories: (context) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CategoriesScreen(viewModel: viewModel),
            ),
          ),
          onOpenRecordingMode: _openRecordingMode,
        ),
      ),
    ),
  );

  Future<void> _openRecordingMode(BuildContext context) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ViewModelHost(
            create: () => RecordingModeViewModel(
              supplies: _deps.supplies,
              restaurants: _deps.restaurants,
              revision: _deps.revision,
            )..load(),
            builder: (_, viewModel) =>
                RecordingModeScreen(viewModel: viewModel),
          ),
        ),
      );

  SupplyDetailViewModel _detail(String supplyId) => SupplyDetailViewModel(
    supplies: _deps.supplies,
    revision: _deps.revision,
    supplyId: supplyId,
  )..load();

  Future<void> openSupply(BuildContext context, Supply supply) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ViewModelHost(
            create: () => _detail(supply.id),
            builder: (_, viewModel) =>
                SupplyDetailScreen(viewModel: viewModel, title: supply.name),
          ),
        ),
      );

  Future<void> openWhyBuy(BuildContext context, String supplyId) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ViewModelHost(
          create: () => _detail(supplyId),
          builder: (_, viewModel) => WhyBuySheet(viewModel: viewModel),
        ),
      );

  Future<void> openDictation(BuildContext context, {VoiceKind? kind}) async {
    final result = await showModalBottomSheet<DictationResult>(
      context: context,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => ViewModelHost(
        create: () => DictationViewModel(
          voice: _deps.voice,
          recorder: _deps.createRecorder(),
          initialKind: kind ?? VoiceKind.forTime(_deps.clock()),
        ),
        builder: (_, viewModel) => DictationSheet(viewModel: viewModel),
      ),
    );
    if (result == null || !context.mounted) return;
    await openReview(context, result.kind, result.draft);
  }

  Future<void> openReview(
    BuildContext context,
    VoiceKind kind,
    VoiceDraft? draft,
  ) async {
    final message = await Navigator.of(context).push(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => switch (kind) {
          VoiceKind.close => ViewModelHost(
            create: () => StockCloseViewModel(
              supplies: _deps.supplies,
              restaurants: _deps.restaurants,
              records: _deps.records,
              drafts: _deps.closeDrafts,
              revision: _deps.revision,
              voice: draft,
              clock: _deps.clock,
            )..load(),
            builder: (_, viewModel) =>
                StockCloseScreen(viewModel: viewModel, catalog: _catalog),
          ),
          VoiceKind.purchase => ViewModelHost(
            create: () => PurchaseReviewViewModel(
              supplies: _deps.supplies,
              restaurants: _deps.restaurants,
              records: _deps.records,
              revision: _deps.revision,
              voice: draft,
              clock: _deps.clock,
            )..load(),
            builder: (_, viewModel) =>
                PurchaseReviewScreen(viewModel: viewModel, catalog: _catalog),
          ),
        },
      ),
    );
    if (message != null && context.mounted) showMessage(context, message);
  }
}

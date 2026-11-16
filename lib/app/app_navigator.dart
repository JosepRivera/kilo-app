import 'package:material_ui/material_ui.dart';

import '../core/widgets/view_model_host.dart';
import '../data/models/supply.dart';
import '../features/settings/categories_screen.dart';
import '../features/settings/recording_mode_screen.dart';
import '../features/settings/recording_mode_view_model.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/settings_view_model.dart';
import '../features/supplies/supply_detail_screen.dart';
import '../features/supplies/supply_detail_view_model.dart';
import '../features/today/why_buy_sheet.dart';
import 'app_dependencies.dart';

class AppNavigator {
  AppNavigator(this._deps);

  final AppDependencies _deps;

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
}

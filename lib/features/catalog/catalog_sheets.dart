import 'package:material_ui/material_ui.dart';

import '../../core/widgets/view_model_host.dart';
import '../../data/models/new_supply.dart';
import '../../data/models/supply_category.dart';
import '../../data/repositories/supply_repository.dart';
import 'catalog_pick.dart';
import 'create_supply_sheet.dart';
import 'search_choice.dart';
import 'supply_search_sheet.dart';
import 'supply_search_view_model.dart';

class CatalogSheets {
  const CatalogSheets(this._supplies);

  final SupplyRepository _supplies;

  Future<NewSupply?> create(
    BuildContext context, {
    required String spoken,
    required List<SupplyCategory> categories,
  }) => showModalBottomSheet<NewSupply>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CreateSupplySheet(spoken: spoken, categories: categories),
  );

  Future<CatalogPick?> search(
    BuildContext context, {
    required List<SupplyCategory> categories,
  }) async {
    final choice = await showModalBottomSheet<SearchChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ViewModelHost(
        create: () => SupplySearchViewModel(_supplies),
        builder: (_, viewModel) => SupplySearchSheet(viewModel: viewModel),
      ),
    );
    final candidate = choice?.candidate;
    if (candidate != null) return CatalogPick.candidate(candidate);
    final newName = choice?.newName;
    if (newName == null || !context.mounted) return null;
    final created = await create(
      context,
      spoken: newName,
      categories: categories,
    );
    return created == null ? null : CatalogPick.create(created);
  }
}

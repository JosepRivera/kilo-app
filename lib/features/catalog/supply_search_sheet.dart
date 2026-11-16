import 'package:material_ui/material_ui.dart';

import '../../core/theme/kilo_colors.dart';
import 'search_choice.dart';
import 'supply_search_view_model.dart';

class SupplySearchSheet extends StatelessWidget {
  const SupplySearchSheet({super.key, required this.viewModel});

  final SupplySearchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: viewModel.search,
                decoration: const InputDecoration(
                  labelText: 'Buscar insumo',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.4,
              ),
              child: ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) => _results(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _results(BuildContext context) {
    if (viewModel.isSearching) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final error = viewModel.error;
    if (error != null) {
      return ListTile(
        title: Text(
          error,
          style: TextStyle(color: KiloColors.of(context).alert),
        ),
      );
    }
    final candidates = viewModel.candidates;
    return ListView.builder(
      shrinkWrap: true,
      itemCount: candidates.length + (viewModel.hasNoMatch ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == candidates.length) {
          return ListTile(
            leading: const Icon(Icons.add),
            title: Text('Crear «${viewModel.term}»'),
            subtitle: const Text('No está en el catálogo'),
            onTap: () =>
                Navigator.of(context).pop(SearchChoice.create(viewModel.term)),
          );
        }
        final candidate = candidates[index];
        return ListTile(
          title: Text(candidate.name),
          subtitle: Text(candidate.unit),
          onTap: () =>
              Navigator.of(context).pop(SearchChoice.candidate(candidate)),
        );
      },
    );
  }
}

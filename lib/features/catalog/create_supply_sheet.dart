import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/widgets/stepper_row.dart';
import '../../data/models/new_supply.dart';
import '../../data/models/supply_category.dart';
import 'creatable_units.dart';

class CreateSupplySheet extends StatefulWidget {
  const CreateSupplySheet({
    super.key,
    required this.spoken,
    required this.categories,
  });

  static const _maxShelfLife = 60;

  final String spoken;
  final List<SupplyCategory> categories;

  @override
  State<CreateSupplySheet> createState() => _CreateSupplySheetState();
}

class _CreateSupplySheetState extends State<CreateSupplySheet> {
  late final TextEditingController _name;
  String _unit = creatableUnits.first;
  String? _categoryId;
  int _shelfLifeDays = 5;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: capitalize(widget.spoken));
    _name.addListener(() => setState(() {}));
    _categoryId = widget.categories.firstOrNull?.id;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canCreate => _name.text.trim().isNotEmpty && _categoryId != null;

  void _create() {
    Navigator.of(context).pop(
      NewSupply(
        name: _name.text.trim(),
        unit: _unit,
        categoryId: _categoryId,
        shelfLifeDays: _shelfLifeDays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nuevo insumo', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final category in widget.categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: const InputDecoration(
                labelText: 'Unidad',
                helperText: 'La unidad no se puede cambiar después.',
              ),
              items: [
                for (final unit in creatableUnits)
                  DropdownMenuItem(value: unit, child: Text(capitalize(unit))),
              ],
              onChanged: (unit) => setState(() => _unit = unit ?? _unit),
            ),
            const SizedBox(height: 8),
            StepperRow(
              label: 'Vence en $_shelfLifeDays días',
              onDecrement: _shelfLifeDays > 1
                  ? () => setState(() => _shelfLifeDays--)
                  : null,
              onIncrement: _shelfLifeDays < CreateSupplySheet._maxShelfLife
                  ? () => setState(() => _shelfLifeDays++)
                  : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _canCreate ? _create : null,
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}

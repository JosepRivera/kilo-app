import 'package:material_ui/material_ui.dart';

import '../core/loadable.dart';
import '../data/models/voice_kind.dart';
import '../features/savings/savings_screen.dart';
import '../features/savings/savings_view_model.dart';
import '../features/supplies/supplies_screen.dart';
import '../features/supplies/supplies_view_model.dart';
import '../features/today/today_screen.dart';
import '../features/today/today_view_model.dart';
import 'app_dependencies.dart';
import 'app_navigator.dart';

class RootTabs extends StatefulWidget {
  const RootTabs({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  static const _dictateIndex = 3;

  late final AppNavigator _navigator = AppNavigator(widget.dependencies);
  late final TodayViewModel _today;
  late final SuppliesViewModel _supplies;
  late final SavingsViewModel _savings;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final deps = widget.dependencies;
    _today = TodayViewModel(
      insights: deps.insights,
      supplies: deps.supplies,
      boughtStore: deps.boughtStore,
      refreshOn: deps.revision,
    )..load();
    _supplies = SuppliesViewModel(
      supplies: deps.supplies,
      restaurants: deps.restaurants,
      refreshOn: deps.revision,
    );
    _savings = SavingsViewModel(
      insights: deps.insights,
      refreshOn: deps.revision,
    );
  }

  @override
  void dispose() {
    _today.dispose();
    _supplies.dispose();
    _savings.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _dictateIndex) {
      _navigator.openDictation(context);
      return;
    }
    final source = <Loadable<Object>>[_today, _supplies, _savings][index];
    if (source.value == null && !source.isLoading) source.load();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          TodayScreen(
            viewModel: _today,
            onOpenSettings: _navigator.openSettings,
            onExplain: _navigator.openWhyBuy,
            onStartFirstCount: (context) =>
                _navigator.openDictation(context, kind: VoiceKind.close),
          ),
          SuppliesScreen(
            viewModel: _supplies,
            onOpenSupply: _navigator.openSupply,
          ),
          SavingsScreen(viewModel: _savings),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Hoy',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Insumos',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Ahorro',
          ),
          NavigationDestination(icon: Icon(Icons.mic), label: 'Dictar'),
        ],
      ),
    );
  }
}

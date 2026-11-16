import 'package:material_ui/material_ui.dart';

import '../core/widgets/view_model_host.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/onboarding_view_model.dart';
import 'app_dependencies.dart';
import 'root_tabs.dart';

class SessionGate extends StatelessWidget {
  const SessionGate({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final session = dependencies.session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        if (!session.isRestored) return const Scaffold();
        if (!session.isSignedIn) {
          return ViewModelHost(
            create: () => OnboardingViewModel(
              restaurants: dependencies.restaurants,
              session: session,
            ),
            builder: (_, viewModel) => OnboardingScreen(viewModel: viewModel),
          );
        }
        return RootTabs(dependencies: dependencies);
      },
    );
  }
}

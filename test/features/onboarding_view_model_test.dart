import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/core/api_exception.dart';
import 'package:kilo_app/data/session.dart';
import 'package:kilo_app/features/onboarding/onboarding_view_model.dart';

import '../support/fake_restaurant_repository.dart';
import '../support/memory_stores.dart';

void main() {
  late FakeRestaurantRepository restaurants;
  late MemoryTokenStore tokens;
  late Session session;
  late OnboardingViewModel viewModel;

  setUp(() {
    restaurants = FakeRestaurantRepository();
    tokens = MemoryTokenStore();
    session = Session(tokens);
    viewModel = OnboardingViewModel(restaurants: restaurants, session: session);
  });

  test('needs a name before submitting', () {
    expect(viewModel.canSubmit, isFalse);
    viewModel.setName('  ');
    expect(viewModel.canSubmit, isFalse);
    viewModel.setName('Doña Rosa');
    expect(viewModel.canSubmit, isTrue);
  });

  test('registers and stores the token securely', () async {
    viewModel
      ..setName(' Doña Rosa ')
      ..setInviteCode(' ');
    await viewModel.submit();
    expect(restaurants.registrations.single, ('Doña Rosa', null));
    expect(tokens.token, 'token-1');
    expect(session.isSignedIn, isTrue);
  });

  test('sends the invite code and shows the server error', () async {
    restaurants.failure = const ApiException(
      403,
      'Código de invitación inválido',
    );
    viewModel
      ..setName('Doña Rosa')
      ..setInviteCode('mal');
    await viewModel.submit();
    expect(viewModel.error, 'Código de invitación inválido');
    expect(viewModel.isSubmitting, isFalse);
    expect(session.isSignedIn, isFalse);
  });

  test('session restores and signs out', () async {
    tokens.token = 'saved';
    final restored = Session(tokens);
    await restored.restore();
    expect(restored.token, 'saved');
    await restored.signOut();
    expect(tokens.token, isNull);
    expect(restored.isSignedIn, isFalse);
  });
}

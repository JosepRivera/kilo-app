import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/core/api_exception.dart';
import 'package:kilo_app/core/data_revision.dart';
import 'package:kilo_app/data/models/month_waste.dart';
import 'package:kilo_app/data/models/savings.dart';
import 'package:kilo_app/features/savings/savings_view_model.dart';
import 'package:kilo_app/features/settings/recording_mode_view_model.dart';
import 'package:kilo_app/features/settings/settings_view_model.dart';

import '../support/fake_insight_repository.dart';
import '../support/fake_record_repository.dart';
import '../support/fake_restaurant_repository.dart';
import '../support/fake_supply_repository.dart';
import '../support/fixtures.dart';

void main() {
  late FakeRestaurantRepository restaurants;
  late FakeRecordRepository records;
  late SettingsViewModel viewModel;

  setUp(() async {
    restaurants = FakeRestaurantRepository();
    records = FakeRecordRepository();
    viewModel = SettingsViewModel(
      restaurants: restaurants,
      records: records,
      revision: DataRevision(),
    );
    await viewModel.load();
  });

  test('toggles recurring closed weekdays', () async {
    await viewModel.toggleClosedWeekday(1);
    expect(viewModel.value!.restaurant.closedWeekdays, [1, 7]);
    await viewModel.toggleClosedWeekday(7);
    expect(viewModel.value!.restaurant.closedWeekdays, [1]);
  });

  test('renames trimming spaces', () async {
    await viewModel.rename('  La Picantería ');
    expect(viewModel.value!.restaurant.name, 'La Picantería');
  });

  test('clamps the purchase interval and edits monthly spend', () async {
    await viewModel.setPurchaseInterval(category, 99);
    expect(restaurants.categoryChanges.last['purchaseIntervalDays'], 60);
    await viewModel.setMonthlySpend(category, 1500);
    expect(viewModel.value!.categories.single.monthlySpend, 1500);
  });

  test('marks no consumption and reports failures', () async {
    expect(await viewModel.markNoConsumption(), isNull);
    expect(records.noConsumptionCalls, 1);
    records.failure = const ApiException(500, 'Falló');
    expect(await viewModel.markNoConsumption(), 'Falló');
  });

  test('recording mode toggles a supply and reloads', () async {
    final supplies = FakeSupplyRepository([supply()]);
    final recording = RecordingModeViewModel(
      supplies: supplies,
      restaurants: restaurants,
      revision: DataRevision(),
    );
    await recording.load();
    expect(recording.sections.single.supplies.single.critical, isTrue);
    await recording.setCritical(supply(), false);
    expect(supplies.criticalChanges, {'chicken-id': false});
  });

  test('savings loads from the server', () async {
    final savings = SavingsViewModel(
      insights: FakeInsightRepository(
        savingsResult: const Savings(
          months: [MonthWaste(month: '2026-11', soles: 200)],
          current: 200,
          previous: 250,
          topWasted: [],
        ),
      ),
    );
    await savings.load();
    expect(savings.value!.current, 200);
  });
}

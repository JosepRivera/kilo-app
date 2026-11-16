import '../../data/models/supply.dart';

class CloseEntry {
  const CloseEntry({
    required this.supply,
    required this.remaining,
    this.suggested,
    this.flagConfirmed = false,
  });

  final Supply supply;
  final double? remaining;
  final double? suggested;
  final bool flagConfirmed;

  CloseEntry edited(double? remaining) =>
      CloseEntry(supply: supply, remaining: remaining);

  CloseEntry withFlagConfirmed() => CloseEntry(
    supply: supply,
    remaining: remaining,
    suggested: suggested,
    flagConfirmed: true,
  );

  CloseEntry withoutSuggestion() => CloseEntry(
    supply: supply,
    remaining: remaining,
    flagConfirmed: flagConfirmed,
  );
}

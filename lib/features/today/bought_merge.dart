import '../../data/models/purchase_suggestion.dart';

class BoughtMerge {
  const BoughtMerge();

  bool isBought(PurchaseSuggestion item, Set<String> checkedSupplyIds) =>
      item.bought || checkedSupplyIds.contains(item.supply.id);
}

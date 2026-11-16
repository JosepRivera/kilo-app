import '../../core/day.dart';
import '../../data/models/supply.dart';
import 'line_problem.dart';
import 'price_flag.dart';
import 'purchase_line_draft.dart';

class PurchaseLineRules {
  const PurchaseLineRules();

  DateTime defaultExpiry(Supply supply, DateTime today) =>
      addDays(today, supply.shelfLifeDays);

  PriceFlag? priceFlag(PurchaseLineDraft line) {
    final check = line.supply?.priceCheck;
    final quantity = line.quantity;
    final cost = line.cost;
    if (check == null || quantity == null || quantity <= 0 || cost == null) {
      return null;
    }
    final unitPrice = cost / quantity;
    if (unitPrice >= check.low && unitPrice <= check.high) return null;
    return PriceFlag(unitPrice: unitPrice, usual: check.usual);
  }

  LineProblem? problem(PurchaseLineDraft line) {
    if (line.supply == null) return LineProblem.unresolved;
    if (line.asksMeasure) return LineProblem.measure;
    final quantity = line.quantity;
    if (quantity == null || quantity <= 0) return LineProblem.quantity;
    final cost = line.cost;
    if (cost == null || cost < 0) return LineProblem.cost;
    if (priceFlag(line) != null && !line.priceConfirmed) {
      return LineProblem.price;
    }
    return null;
  }

  bool isValid(PurchaseLineDraft line) => problem(line) == null;
}

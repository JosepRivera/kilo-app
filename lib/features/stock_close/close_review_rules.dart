import '../../data/models/supply.dart';
import 'close_flag.dart';

class CloseReviewRules {
  const CloseReviewRules();

  CloseFlag? flag(Supply supply, double remaining) {
    final check = supply.closeCheck;
    if (check == null || remaining >= check.reviewBelow) return null;
    final consumed = (check.base - remaining) / check.gapDays;
    return CloseFlag(consumed: consumed < 0 ? 0 : consumed, usual: check.usual);
  }
}

import 'package:flutter/foundation.dart';

class DataRevision extends ChangeNotifier {
  void bump() => notifyListeners();
}

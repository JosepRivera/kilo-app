import 'package:flutter/foundation.dart';

import 'stores/token_store.dart';

class Session extends ChangeNotifier {
  Session(this._store);

  final TokenStore _store;
  String? _token;
  bool _restored = false;

  String? get token => _token;
  bool get isRestored => _restored;
  bool get isSignedIn => _token != null;

  Future<void> restore() async {
    _token = await _store.read();
    _restored = true;
    notifyListeners();
  }

  Future<void> signIn(String token) async {
    await _store.write(token);
    _token = token;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_token == null) return;
    _token = null;
    notifyListeners();
    await _store.clear();
  }
}

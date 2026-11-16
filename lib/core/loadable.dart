import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_exception.dart';

abstract class Loadable<T> extends ChangeNotifier {
  Loadable({this._refreshOn}) {
    _refreshOn?.addListener(_refresh);
  }

  final Listenable? _refreshOn;
  T? _value;
  String? _error;
  bool _loading = false;
  bool _disposed = false;

  T? get value => _value;
  String? get error => _error;
  bool get isLoading => _loading;

  @protected
  Future<T> fetch();

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _value = await fetch();
    } on ApiException catch (failure) {
      _error = failure.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @protected
  void update(T value) {
    _value = value;
    notifyListeners();
  }

  @protected
  Future<String?> attempt(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on ApiException catch (failure) {
      return failure.message;
    }
  }

  void _refresh() {
    if (_value != null || _error != null) unawaited(load());
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshOn?.removeListener(_refresh);
    super.dispose();
  }
}

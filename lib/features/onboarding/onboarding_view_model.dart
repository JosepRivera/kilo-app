import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../data/repositories/restaurant_repository.dart';
import '../../data/session.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({required this._restaurants, required this._session});

  final RestaurantRepository _restaurants;
  final Session _session;
  String _name = '';
  String _inviteCode = '';
  bool _submitting = false;
  String? _error;

  bool get isSubmitting => _submitting;
  bool get canSubmit => _name.trim().isNotEmpty && !_submitting;
  String? get error => _error;

  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  void setInviteCode(String inviteCode) => _inviteCode = inviteCode;

  Future<void> submit() async {
    if (!canSubmit) return;
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      final inviteCode = _inviteCode.trim();
      final registration = await _restaurants.register(
        name: _name.trim(),
        inviteCode: inviteCode.isEmpty ? null : inviteCode,
      );
      await _session.signIn(registration.token);
    } on ApiException catch (failure) {
      _error = failure.message;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}

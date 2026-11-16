import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../data/models/catalog_candidate.dart';
import '../../data/models/resolution_kind.dart';
import '../../data/repositories/supply_repository.dart';

class SupplySearchViewModel extends ChangeNotifier {
  SupplySearchViewModel(this._supplies);

  final SupplyRepository _supplies;
  String _term = '';
  List<CatalogCandidate> _candidates = const [];
  bool _searching = false;
  bool _searched = false;
  String? _error;
  int _generation = 0;

  String get term => _term;
  List<CatalogCandidate> get candidates => _candidates;
  bool get isSearching => _searching;
  bool get hasNoMatch => _searched && !_searching && _candidates.isEmpty;
  String? get error => _error;

  Future<void> search(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    final generation = ++_generation;
    _term = trimmed;
    _searching = true;
    _error = null;
    notifyListeners();
    try {
      final resolution = await _supplies.resolve(trimmed);
      if (generation != _generation) return;
      _candidates = resolution.kind == ResolutionKind.unknown
          ? const []
          : resolution.candidates;
    } on ApiException catch (failure) {
      if (generation != _generation) return;
      _candidates = const [];
      _error = failure.message;
    }
    _searching = false;
    _searched = true;
    notifyListeners();
  }
}

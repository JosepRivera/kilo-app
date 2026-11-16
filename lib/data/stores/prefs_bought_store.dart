import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../json.dart';
import 'bought_store.dart';

class PrefsBoughtStore implements BoughtStore {
  const PrefsBoughtStore(this._prefs);

  static const _key = 'bought_today';

  final SharedPreferencesAsync _prefs;

  @override
  Future<Set<String>> read(String day) async {
    final stored = await _prefs.getString(_key);
    if (stored == null) return {};
    final json = jsonDecode(stored) as Json;
    if (json['day'] != day) return {};
    return {
      for (final id in json['supplyIds']! as List<Object?>) id! as String,
    };
  }

  @override
  Future<void> write(String day, Set<String> supplyIds) => _prefs.setString(
    _key,
    jsonEncode({'day': day, 'supplyIds': supplyIds.toList()}),
  );
}

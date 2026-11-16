import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../json.dart';
import '../models/close_draft.dart';
import 'close_draft_store.dart';

class PrefsCloseDraftStore implements CloseDraftStore {
  const PrefsCloseDraftStore(this._prefs);

  static const _key = 'close_draft';

  final SharedPreferencesAsync _prefs;

  @override
  Future<CloseDraft?> read() async {
    final stored = await _prefs.getString(_key);
    return stored == null
        ? null
        : CloseDraft.fromJson(jsonDecode(stored) as Json);
  }

  @override
  Future<void> write(CloseDraft draft) =>
      _prefs.setString(_key, jsonEncode(draft.toJson()));

  @override
  Future<void> clear() => _prefs.remove(_key);
}

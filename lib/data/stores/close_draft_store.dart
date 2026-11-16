import '../models/close_draft.dart';

abstract interface class CloseDraftStore {
  Future<CloseDraft?> read();

  Future<void> write(CloseDraft draft);

  Future<void> clear();
}

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'outbox_action.dart';

class OutboxService {
  OutboxService._();
  static final OutboxService instance = OutboxService._();

  static const String _boxName = "outbox_box";
  Box? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  int get pendingCount => _box?.length ?? 0;

  List<OutboxAction> getAll() {
    final b = _box;
    if (b == null) return [];
    return b.values
        .map((e) => OutboxAction.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
  }

  Future<void> add({
    required String type,
    required String docPath,
    required Map<String, dynamic> payload,
  }) async {
    final b = _box;
    if (b == null) return;

    final action = OutboxAction(
      id: const Uuid().v4(),
      type: type,
      docPath: docPath,
      payload: payload,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    await b.put(action.id, action.toMap());
  }

  Future<void> remove(String id) async {
    await _box?.delete(id);
  }

  Future<void> updateRetry(String id, int retry) async {
    final b = _box;
    if (b == null) return;

    final data = b.get(id);
    if (data == null) return;

    final m = Map<String, dynamic>.from(data);
    m["retryCount"] = retry;
    await b.put(id, m);
  }
}

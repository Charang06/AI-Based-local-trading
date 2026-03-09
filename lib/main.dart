import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/splash_screen.dart';
import 'services/sync_status_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Initialize Firebase
  await Firebase.initializeApp();

  // 🔹 Enable Firestore Offline Persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // 🔹 Initialize Hive
  await Hive.initFlutter();

  // 🔹 Local cache boxes
  await Hive.openBox('products_cache');
  await Hive.openBox('messages_cache');
  await Hive.openBox('negotiations_cache');
  await Hive.openBox('myads_cache');
  await Hive.openBox('orders_cache');

  // 🔹 Offline action queue
  await Hive.openBox('outbox');

  runApp(const TradeConnectApp());
}

class TradeConnectApp extends StatefulWidget {
  const TradeConnectApp({super.key});

  @override
  State<TradeConnectApp> createState() => _TradeConnectAppState();
}

class _TradeConnectAppState extends State<TradeConnectApp> {
  final SyncStatusController sync = SyncStatusController();

  @override
  void initState() {
    super.initState();

    // 🔹 Start sync controller
    sync.start(outbox: Hive.box('outbox'), performSync: _performSync);
  }

  @override
  void dispose() {
    sync.dispose();
    super.dispose();
  }

  /// 🔹 Reads outbox and pushes actions to Firestore
  Future<void> _performSync() async {
    if (!sync.isOnline) return;

    final outbox = Hive.box('outbox');
    if (outbox.isEmpty) return;

    final keys = outbox.keys.toList();

    for (final key in keys) {
      final raw = outbox.get(key);

      if (raw == null) {
        await outbox.delete(key);
        continue;
      }

      final action = Map<String, dynamic>.from(raw as Map);
      final type = (action["type"] ?? "").toString();

      try {
        // 🔹 CREATE / SET
        if (type == "fs_set") {
          final path = (action["path"] ?? "").toString();
          final data = Map<String, dynamic>.from(action["data"] ?? {});

          if (path.isNotEmpty) {
            await FirebaseFirestore.instance
                .doc(path)
                .set(data, SetOptions(merge: true));

            await outbox.delete(key);
          }
        }
        // 🔹 UPDATE
        else if (type == "fs_update") {
          final path = (action["path"] ?? "").toString();
          final data = Map<String, dynamic>.from(action["data"] ?? {});

          if (path.isNotEmpty) {
            // convert soldAtLocal → server timestamp
            if (path.startsWith("products/") &&
                data["status"] == "sold" &&
                data.containsKey("soldAtLocal")) {
              data.remove("soldAtLocal");
              data["soldAt"] = FieldValue.serverTimestamp();
            }

            if (data.isNotEmpty) {
              await FirebaseFirestore.instance.doc(path).update(data);
            }

            await outbox.delete(key);
          }
        }
        // 🔹 DELETE
        else if (type == "fs_delete") {
          final path = (action["path"] ?? "").toString();

          if (path.isNotEmpty) {
            await FirebaseFirestore.instance.doc(path).delete();
            await outbox.delete(key);
          }
        }
        // 🔹 UNKNOWN ACTION (skip but keep)
        else {
          continue;
        }
      } catch (e) {
        // 🔹 store error and retry later
        sync.setError(e.toString());
        break;
      }
    }

    sync.setError(null);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sync,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // 🔹 Future: global banner support
          builder: (context, child) {
            return Column(
              children: [
                if (!sync.isOnline || sync.pending > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: sync.isOnline ? Colors.orange : Colors.red,
                    child: Text(
                      sync.isOnline
                          ? "Sync pending: ${sync.pending}"
                          : "Offline mode",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(child: child ?? const SizedBox()),
              ],
            );
          },

          home: const SplashScreen(),
        );
      },
    );
  }
}

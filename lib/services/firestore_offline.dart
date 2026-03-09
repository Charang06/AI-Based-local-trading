import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreOffline {
  static Future<void> init() async {
    final db = FirebaseFirestore.instance;

    // Works for Android/iOS. (Web needs different handling)
    db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}

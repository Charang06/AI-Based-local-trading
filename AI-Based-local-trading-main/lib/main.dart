import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/splash_screen.dart';
import 'services/connectivity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Option 1 Offline: Firestore local cache + queued writes
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  ConnectivityService.instance.start(); // ✅ start listener

  runApp(const TradeConnectApp());
}

class TradeConnectApp extends StatelessWidget {
  const TradeConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

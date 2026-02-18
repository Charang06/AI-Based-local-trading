import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final bool online;
  const OfflineBanner({super.key, required this.online});

  @override
  Widget build(BuildContext context) {
    if (online) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: const Color(0xFFFFF7D6),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Color(0xFFB45309)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "You're Offline. Changes will sync automatically.",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/sync_status_controller.dart';

class GlobalSyncBanner extends StatelessWidget {
  final SyncStatusController controller;
  final Future<void> Function() onSyncNow;
  final double height;

  const GlobalSyncBanner({
    super.key,
    required this.controller,
    required this.onSyncNow,
    this.height = 62,
  });

  @override
  Widget build(BuildContext context) {
    final show =
        !controller.isOnline ||
        controller.isSyncing ||
        controller.pending > 0 ||
        controller.lastError != null;

    String title;
    String subtitle;
    Color bg;
    Color fg;
    IconData icon;

    if (!controller.isOnline) {
      title = "You're Offline";
      subtitle = "Changes will sync when internet is back.";
      bg = const Color(0xFFFFF3B0);
      fg = const Color(0xFF111827);
      icon = Icons.wifi_off;
    } else if (controller.isSyncing) {
      title = "Syncing...";
      subtitle = "Uploading your offline changes.";
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0F172A);
      icon = Icons.sync;
    } else if (controller.lastError != null) {
      title = "Sync failed";
      subtitle = "Tap Sync Now to retry.";
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF7F1D1D);
      icon = Icons.error_outline;
    } else {
      title = "Pending sync";
      subtitle = "${controller.pending} changes waiting to sync.";
      bg = const Color(0xFFFFF3B0);
      fg = const Color(0xFF111827);
      icon = Icons.schedule;
    }

    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      offset: show ? Offset.zero : const Offset(0, -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: show ? height : 0,
        child: show
            ? Material(
                elevation: 6,
                color: bg,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    child: Row(
                      children: [
                        Icon(icon, color: fg),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: fg,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: fg, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (controller.isSyncing)
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(fg),
                            ),
                          )
                        else
                          TextButton(
                            onPressed: controller.isOnline
                                ? () async => controller.syncNow(onSyncNow)
                                : null,
                            style: TextButton.styleFrom(
                              backgroundColor: fg,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Sync Now",
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

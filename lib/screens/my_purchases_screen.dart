import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyPurchasesScreen extends StatefulWidget {
  const MyPurchasesScreen({super.key});

  @override
  State<MyPurchasesScreen> createState() => _MyPurchasesScreenState();
}

class _MyPurchasesScreenState extends State<MyPurchasesScreen> {
  String tab = "pending"; // pending/accepted/rejected/completed/cancelled/all

  // Prevent repeated popups in same session
  final Set<String> _popped = {};

  Query<Map<String, dynamic>> _query(String uid) {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection("orders")
        .where("buyerId", isEqualTo: uid)
        .orderBy("createdAt", descending: true);

    if (tab != "all") {
      q = q.where("status", isEqualTo: tab);
    }
    return q;
  }

  Future<void> _markRead(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection("orders").doc(orderId).set({
        "hasUnreadForBuyer": false,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection("orders").doc(orderId).set({
        "status": "cancelled",
        "updatedAt": FieldValue.serverTimestamp(),
        "hasUnreadForSeller": true,
        "hasUnreadForBuyer": false,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Order cancelled ✅")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Cancel failed: $e")));
    }
  }

  String _fmtTs(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      return "${d.day}/${d.month} $hh:$mm";
    }
    return "";
  }

  void _showStatusPopup({
    required String orderId,
    required String productTitle,
    required String newStatus,
  }) {
    if (_popped.contains(orderId)) return;
    _popped.add(orderId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      String msg = "Order update: $productTitle → $newStatus";
      if (newStatus == "accepted") msg = "✅ Accepted: $productTitle";
      if (newStatus == "rejected") msg = "❌ Rejected: $productTitle";
      if (newStatus == "completed") msg = "📦 Completed: $productTitle";
      if (newStatus == "cancelled") msg = "🚫 Cancelled: $productTitle";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      // mark read so it won't show again after refresh
      _markRead(orderId);
    });
  }

  bool _shouldPopup(String status) {
    return status == "accepted" ||
        status == "rejected" ||
        status == "completed" ||
        status == "cancelled";
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please login first.")));
    }

    final q = _query(uid);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4FFFA), Color(0xFFEFF7FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF2A7BF4)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        "My Purchases",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _tabs(),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: q.snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text("Error: ${snap.error}"));
                    }

                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text("No orders found."));
                    }

                    // ✅ popup when unread + status is final
                    for (final doc in docs) {
                      final d = doc.data();
                      final orderId = doc.id;
                      final status = (d["status"] ?? "pending").toString();
                      final title = (d["productTitle"] ?? "Product").toString();
                      final unread = (d["hasUnreadForBuyer"] as bool?) ?? false;

                      if (unread && _shouldPopup(status)) {
                        _showStatusPopup(
                          orderId: orderId,
                          productTitle: title,
                          newStatus: status,
                        );
                      }
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final d = doc.data();

                        final status = (d["status"] ?? "pending").toString();
                        final productTitle = (d["productTitle"] ?? "Product")
                            .toString();

                        final qty = (d["qty"] as num?)?.toDouble() ?? 1;
                        final unit = (d["unit"] ?? "unit").toString();
                        final totalRs = (d["totalRs"] as num?)?.toInt() ?? 0;

                        final timeText = _fmtTs(d["createdAt"]);
                        final paymentMethod = (d["paymentMethod"] ?? "cash")
                            .toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF7FF),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Color(0xFF2A7BF4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$qty $unit • Total Rs $totalRs",
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Payment: $paymentMethod • $timeText",
                                          style: const TextStyle(
                                            color: Colors.black45,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _statusPill(status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (status == "pending")
                                _actionBtn(
                                  text: "Cancel Order",
                                  color: const Color(0xFFEF4444),
                                  onTap: () => _cancelOrder(doc.id),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    return Row(
      children: [
        Expanded(child: _tabBtn("Pending", "pending")),
        const SizedBox(width: 8),
        Expanded(child: _tabBtn("Accepted", "accepted")),
        const SizedBox(width: 8),
        Expanded(child: _tabBtn("Rejected", "rejected")),
        const SizedBox(width: 8),
        Expanded(child: _tabBtn("Done", "completed")),
        const SizedBox(width: 8),
        Expanded(child: _tabBtn("All", "all")),
      ],
    );
  }

  Widget _tabBtn(String label, String value) {
    final active = tab == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => tab = value),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2A7BF4) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: active ? Colors.white : Colors.black87,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    if (status == "accepted") {
      return _pill(
        "Accepted",
        const Color(0xFFD9FFE6),
        const Color(0xFF16A34A),
      );
    }
    if (status == "rejected") {
      return _pill(
        "Rejected",
        const Color(0xFFFFECEC),
        const Color(0xFFEF4444),
      );
    }
    if (status == "completed") {
      return _pill("Done", const Color(0xFFEAF7FF), const Color(0xFF2A7BF4));
    }
    if (status == "cancelled") {
      return _pill("Cancelled", const Color(0xFFE5E7EB), Colors.black54);
    }
    return _pill("Pending", const Color(0xFFFFF7D6), const Color(0xFFB45309));
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }

  Widget _actionBtn({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

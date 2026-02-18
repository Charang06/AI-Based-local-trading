import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  String tab = "pending"; // pending/accepted/rejected/completed/all

  Query<Map<String, dynamic>> _query(String uid) {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection("orders")
        .where("sellerId", isEqualTo: uid)
        .orderBy("createdAt", descending: true);

    if (tab != "all") {
      q = q.where("status", isEqualTo: tab);
    }
    return q;
  }

  Future<void> _setStatus(String orderId, String status) async {
    try {
      await FirebaseFirestore.instance.collection("orders").doc(orderId).set({
        "status": status,
        "updatedAt": FieldValue.serverTimestamp(),

        // ✅ notify buyer + clear seller unread
        "hasUnreadForBuyer": true,
        "hasUnreadForSeller": false,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Order marked as $status ✅")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
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
                        "My Orders",
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

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final d = doc.data();

                        final status = (d["status"] ?? "pending").toString();
                        final productTitle = (d["productTitle"] ?? "Product")
                            .toString();
                        final buyerName = (d["buyerName"] ?? "Buyer")
                            .toString();
                        final buyerPhone = (d["buyerPhone"] ?? "").toString();

                        final qty = (d["qty"] as num?)?.toDouble() ?? 1;
                        final unit = (d["unit"] ?? "unit").toString();
                        final priceRs = (d["priceRs"] as num?)?.toInt() ?? 0;

                        final totalRs =
                            (d["totalRs"] as num?)?.toInt() ??
                            (priceRs * qty).round();

                        final address = (d["deliveryAddress"] ?? "").toString();
                        final note = (d["note"] ?? "").toString();
                        final timeText = _fmtTs(d["createdAt"]);

                        final unread =
                            (d["hasUnreadForSeller"] as bool?) ?? false;

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
                                      Icons.inventory_2_outlined,
                                      color: Color(0xFF2A7BF4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                productTitle,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            if (unread)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFF5A5A,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: const Text(
                                                  "NEW",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$qty $unit • Rs $priceRs  (Total: Rs $totalRs)",
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          timeText,
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

                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "$buyerName ${buyerPhone.isEmpty ? "" : "• $buyerPhone"}",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              if (address.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        address,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              if (note.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  "Note: $note",
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),

                              if (status == "pending") ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _actionBtn(
                                        text: "Accept",
                                        color: const Color(0xFF22C55E),
                                        onTap: () =>
                                            _setStatus(doc.id, "accepted"),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _actionBtn(
                                        text: "Reject",
                                        color: const Color(0xFFEF4444),
                                        onTap: () =>
                                            _setStatus(doc.id, "rejected"),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (status == "accepted") ...[
                                _actionBtn(
                                  text: "Mark Completed",
                                  color: const Color(0xFF2A7BF4),
                                  onTap: () => _setStatus(doc.id, "completed"),
                                ),
                              ],
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
    if (status == "accepted")
      return _pill(
        "Accepted",
        const Color(0xFFD9FFE6),
        const Color(0xFF16A34A),
      );
    if (status == "rejected")
      return _pill(
        "Rejected",
        const Color(0xFFFFECEC),
        const Color(0xFFEF4444),
      );
    if (status == "completed")
      return _pill("Done", const Color(0xFFEAF7FF), const Color(0xFF2A7BF4));
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

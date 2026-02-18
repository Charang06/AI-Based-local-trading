import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'offer_detail_screen.dart';

class ManageOffersScreen extends StatefulWidget {
  const ManageOffersScreen({super.key});

  @override
  State<ManageOffersScreen> createState() => _ManageOffersScreenState();
}

class _ManageOffersScreenState extends State<ManageOffersScreen> {
  String tab = "pending"; // pending / accepted / rejected / all

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Please login first.")),
      );
    }

    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection("negotiations")
        .where("participants", arrayContains: uid)
        .orderBy("updatedAt", descending: true);

    if (tab != "all") {
      q = q.where("status", isEqualTo: tab);
    }

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
              // Gradient header like your UI
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF2A7BF4)],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
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
                        "Manage Offers",
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

              // Tabs row
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
                      return const Center(child: Text("No offers found."));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final d = doc.data();

                        final productTitle =
                            (d["productTitle"] ?? "Product").toString();
                        final lastMessage = (d["lastMessage"] ?? "").toString();
                        final status = (d["status"] ?? "pending").toString();

                        final sellerId = (d["sellerId"] ?? "").toString();

                        // ✅ Use buyerId (so no "unused" warning) + show correct other role
                        final buyerId = (d["buyerId"] ?? "").toString();
                        final amSeller = sellerId == uid;
                        final otherUserId = amSeller ? buyerId : sellerId;
                        final otherRole = amSeller ? "Buyer" : "Seller";

                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OfferDetailScreen(
                                  negotiationId: doc.id,
                                  productTitle: productTitle,
                                  amSeller: amSeller,
                                  // If your OfferDetailScreen supports it, pass it.
                                  // If not, you can remove this line.
                                  otherUserId: otherUserId,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  // ✅ replace withOpacity (deprecated)
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF7FF),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.local_offer,
                                      color: Color(0xFF2A7BF4)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productTitle,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastMessage.isEmpty
                                            ? "Tap to open offer chat"
                                            : lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.black54, fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _pill(otherRole,
                                              const Color(0xFFF3F4F6),
                                              Colors.black87),
                                          const SizedBox(width: 8),
                                          _statusPill(status),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: Colors.black45),
                              ],
                            ),
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
        height: 42,
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
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }

  Widget _statusPill(String status) {
    if (status == "accepted") {
      return _pill("Accepted", const Color(0xFFD9FFE6), const Color(0xFF16A34A));
    }
    if (status == "rejected") {
      return _pill("Rejected", const Color(0xFFFFECEC), Colors.red);
    }
    return _pill("Pending", const Color(0xFFFFF7D6), const Color(0xFFB45309));
  }
}

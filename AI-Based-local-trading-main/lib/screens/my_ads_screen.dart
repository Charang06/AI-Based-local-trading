import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'edit_product_screen.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  String tab = "active"; // active / sold / all

  Query<Map<String, dynamic>> _query(String uid) {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection("products")
        .where("sellerId", isEqualTo: uid)
        .orderBy("createdAt", descending: true);

    if (tab != "all") {
      q = q.where("status", isEqualTo: tab);
    }
    return q;
  }

  Future<void> _deleteAd(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection("products")
          .doc(productId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ad deleted ✅")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  Future<void> _markSold(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection("products")
          .doc(productId)
          .set({
            "status": "sold",
            "soldAt": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Marked as sold ✅")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    }
  }

  String _fmtPrice(dynamic v) {
    final n = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
    return "Rs $n";
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
                        "My Ads",
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
                child: Row(
                  children: [
                    Expanded(child: _tabBtn("Active", "active")),
                    const SizedBox(width: 8),
                    Expanded(child: _tabBtn("Sold", "sold")),
                    const SizedBox(width: 8),
                    Expanded(child: _tabBtn("All", "all")),
                  ],
                ),
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
                      return const Center(child: Text("No ads found."));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final d = doc.data();

                        final title = (d["title"] ?? "").toString();
                        final imageUrl = (d["imageUrl"] ?? "").toString();
                        final status = (d["status"] ?? "active").toString();
                        final qty = (d["qty"] as num?)?.toDouble() ?? 1;
                        final unit = (d["unit"] ?? "unit").toString();
                        final price = _fmtPrice(d["priceRs"]);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: imageUrl.isEmpty
                                    ? Container(
                                        width: 64,
                                        height: 64,
                                        color: const Color(0xFFE5E7EB),
                                        child: const Icon(
                                          Icons.image_not_supported_outlined,
                                        ),
                                      )
                                    : Image.network(
                                        imageUrl,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title.isEmpty ? "Untitled" : title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "$qty $unit • $price",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _statusPill(status),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Actions
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == "edit") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditProductScreen(
                                          productId: doc.id,
                                        ),
                                      ),
                                    );
                                  }
                                  if (v == "sold") {
                                    await _markSold(doc.id);
                                  }
                                  if (v == "delete") {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text("Delete Ad?"),
                                        content: const Text(
                                          "This cannot be undone.",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text("Cancel"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text("Delete"),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) await _deleteAd(doc.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: "edit",
                                    child: Text("Edit"),
                                  ),
                                  if (status == "active")
                                    const PopupMenuItem(
                                      value: "sold",
                                      child: Text("Mark Sold"),
                                    ),
                                  const PopupMenuItem(
                                    value: "delete",
                                    child: Text("Delete"),
                                  ),
                                ],
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
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    if (status == "sold") {
      return _pill("SOLD", const Color(0xFFE5E7EB), Colors.black54);
    }
    return _pill("ACTIVE", const Color(0xFFD9FFE6), const Color(0xFF16A34A));
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
}

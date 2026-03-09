import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  String tab = "all"; // all/pending/accepted/rejected/completed

  Query<Map<String, dynamic>> _query(String uid) {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection("orders")
        .where("buyerId", isEqualTo: uid)
        .orderBy("createdAt", descending: true);

    if (tab != "all") q = q.where("status", isEqualTo: tab);
    return q;
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
      appBar: AppBar(title: const Text("My Purchases")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                _chip("All", "all"),
                _chip("Pending", "pending"),
                _chip("Accepted", "accepted"),
                _chip("Rejected", "rejected"),
                _chip("Done", "completed"),
              ],
            ),
          ),
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
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final status = (d["status"] ?? "pending").toString();
                    final title = (d["productTitle"] ?? "Product").toString();
                    final qty = (d["qty"] as num?)?.toDouble() ?? 1;
                    final unit = (d["unit"] ?? "unit").toString();
                    final total = (d["totalRs"] as num?)?.toInt() ?? 0;
                    final time = _fmtTs(d["createdAt"]);

                    return Card(
                      child: ListTile(
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Text("$qty $unit • Rs $total\n$time"),
                        trailing: _statusPill(status),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final active = tab == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => setState(() => tab = value),
    );
  }

  Widget _statusPill(String status) {
    Color bg;
    Color fg;
    String text = status;

    switch (status) {
      case "accepted":
        bg = const Color(0xFFD9FFE6);
        fg = const Color(0xFF16A34A);
        text = "Accepted";
        break;
      case "rejected":
        bg = const Color(0xFFFFECEC);
        fg = const Color(0xFFEF4444);
        text = "Rejected";
        break;
      case "completed":
        bg = const Color(0xFFEAF7FF);
        fg = const Color(0xFF2A7BF4);
        text = "Done";
        break;
      default:
        bg = const Color(0xFFFFF7D6);
        fg = const Color(0xFFB45309);
        text = "Pending";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product.dart';
import 'start_negotiation_screen.dart';

class NegotiationsListScreen extends StatelessWidget {
  const NegotiationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please login first.")));
    }

    final query = FirebaseFirestore.instance
        .collection("negotiations")
        .where("participants", arrayContains: uid)
        .orderBy("updatedAt", descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Offers"),
        backgroundColor: const Color(0xFF2A7BF4),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No offers yet."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final productId = (d["productId"] ?? "").toString();
              final productTitle = (d["productTitle"] ?? "Product").toString();
              final last = (d["lastMessage"] ?? "").toString();
              final updatedAt = d["updatedAt"];

              return _OfferTile(
                productId: productId,
                productTitle: productTitle,
                lastMessage: last,
                timeText: _formatTime(updatedAt),
                onOpen: () async {
                  if (productId.isEmpty) return;

                  // 1) load product doc
                  final pSnap = await FirebaseFirestore.instance
                      .collection("products")
                      .doc(productId)
                      .get();

                  if (!context.mounted) return;

                  final pData = pSnap.data();
                  if (pData == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Product not found.")),
                    );
                    return;
                  }

                  // safe reads
                  final priceRs = (pData["priceRs"] as num?)?.toInt() ?? 0;
                  final qty = (pData["qty"] as num?)?.toDouble() ?? 1.0;
                  final unit = (pData["unit"] ?? "pcs").toString();

                  final baseQty = (pData["baseQty"] as num?)?.toDouble() ?? qty;
                  final baseUnit = (pData["baseUnit"] ?? unit).toString();

                  final pricePerBase =
                      (pData["pricePerBase"] as num?)?.toDouble() ??
                      (baseQty > 0 ? priceRs / baseQty : 0);

                  // 2) build Product object
                  final product = Product(
                    id: productId,
                    title: (pData["title"] ?? productTitle).toString(),
                    imageUrl: (pData["imageUrl"] ?? "").toString(),
                    priceRs: priceRs,

                    qty: qty,
                    unit: unit,
                    baseQty: baseQty,
                    baseUnit: baseUnit,
                    pricePerBase: pricePerBase,

                    aiPriceRs: (pData["aiPriceRs"] as num?)?.toInt() ?? 0,
                    fairDeal: (pData["fairDeal"] as bool?) ?? false,
                    marketLow: (pData["marketLow"] as num?)?.toInt() ?? 0,
                    marketHigh: (pData["marketHigh"] as num?)?.toInt() ?? 0,

                    sellerId: (pData["sellerId"] ?? "").toString(),
                    sellerName: (pData["sellerName"] ?? "").toString(),
                    sellerPhone: (pData["sellerPhone"] ?? "").toString(),
                    sellerRating:
                        (pData["sellerRating"] as num?)?.toDouble() ?? 0,

                    distanceKm: (pData["distanceKm"] as num?)?.toDouble() ?? 0,
                    locationName: (pData["locationName"] ?? "Unknown")
                        .toString(),
                    lat: (pData["lat"] as num?)?.toDouble() ?? 0,
                    lng: (pData["lng"] as num?)?.toDouble() ?? 0,

                    description: (pData["description"] ?? "").toString(),
                    tags: List<String>.from(pData["tags"] ?? const []),
                    category: (pData["category"] ?? "Other").toString(),

                    status: (pData["status"] ?? "active").toString(),
                    createdAt: (pData["createdAt"] is Timestamp)
                        ? (pData["createdAt"] as Timestamp).toDate()
                        : null,
                    soldAt: (pData["soldAt"] is Timestamp)
                        ? (pData["soldAt"] as Timestamp).toDate()
                        : null,
                  );

                  // 3) open chat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StartNegotiationScreen(product: product),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static String _formatTime(dynamic ts) {
    if (ts == null) return "";
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    return "";
  }
}

class _OfferTile extends StatelessWidget {
  final String productId;
  final String productTitle;
  final String lastMessage;
  final String timeText;
  final VoidCallback onOpen;

  const _OfferTile({
    required this.productId,
    required this.productTitle,
    required this.lastMessage,
    required this.timeText,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            _ProductThumb(productId: productId),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastMessage.isEmpty ? "Tap to open chat" : lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeText,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                const Icon(Icons.chevron_right, color: Colors.black45),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final String productId;
  const _ProductThumb({required this.productId});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 58,
        height: 58,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection("products")
              .doc(productId)
              .snapshots(),
          builder: (context, snap) {
            final img = snap.data?.data()?["imageUrl"]?.toString() ?? "";
            if (img.isEmpty) {
              return Container(
                color: const Color(0xFFE5E7EB),
                alignment: Alignment.center,
                child: const Icon(Icons.image, color: Colors.black45),
              );
            }
            return Image.network(
              img,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFE5E7EB),
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, color: Colors.black45),
              ),
            );
          },
        ),
      ),
    );
  }
}

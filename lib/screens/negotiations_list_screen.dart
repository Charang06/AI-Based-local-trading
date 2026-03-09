import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

import '../models/product.dart';
import 'start_negotiation_screen.dart';

class NegotiationsListScreen extends StatelessWidget {
  const NegotiationsListScreen({super.key});

  static const String _cacheBox = "negotiations_cache";

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
          // ✅ ONLINE data available
          if (snap.hasData) {
            final docs = snap.data?.docs ?? [];

            // save to Hive (per user)
            _saveCache(uid, docs);

            if (docs.isEmpty) {
              return const Center(child: Text("No offers yet."));
            }

            return _buildListFromDocs(context, docs);
          }

          // ✅ OFFLINE / ERROR fallback
          final cached = _loadCache(uid);

          if (cached.isEmpty) {
            if (snap.hasError) {
              return Center(
                child: Text("Offline (no cache yet)\n${snap.error}"),
              );
            }
            return const Center(child: Text("Offline (no cache yet)."));
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7D6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Color(0xFFB45309)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Offline mode: showing cached offers",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildListFromCache(context, cached)),
            ],
          );
        },
      ),
    );
  }

  // ---------------- CACHE ----------------

  static Future<void> _saveCache(
    String uid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final box = Hive.box(_cacheBox);
    final key = "${uid}_list";

    final list = docs.map((d) {
      final data = d.data();
      return {"id": d.id, ...data};
    }).toList();

    await box.put(key, list);
    await box.put("${key}_time", DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>> _loadCache(String uid) {
    final box = Hive.box(_cacheBox);
    final key = "${uid}_list";

    final raw = box.get(key);
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ---------------- LIST BUILDERS ----------------

  Widget _buildListFromDocs(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final d = docs[i].data();
        return _offerTileFromMap(context, d);
      },
    );
  }

  Widget _buildListFromCache(
    BuildContext context,
    List<Map<String, dynamic>> cached,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: cached.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final d = cached[i];
        return _offerTileFromMap(context, d);
      },
    );
  }

  Widget _offerTileFromMap(BuildContext context, Map<String, dynamic> d) {
    final productId = (d["productId"] ?? "").toString();
    final productTitle = (d["productTitle"] ?? "Product").toString();
    final last = (d["lastMessage"] ?? "").toString();
    final updatedAt = d["updatedAt"];

    return _OfferTile(
      productId: productId,
      productTitle: productTitle,
      lastMessage: last,
      timeText: _formatTime(updatedAt),
      // ✅ Optional: if you already store productImageUrl inside negotiation doc, use it
      cachedImageUrl: (d["productImageUrl"] ?? "").toString(),
      onOpen: () async {
        if (productId.isEmpty) return;

        final pSnap = await FirebaseFirestore.instance
            .collection("products")
            .doc(productId)
            .get();

        if (!context.mounted) return;

        final pData = pSnap.data();
        if (pData == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Product not found.")));
          return;
        }

        final priceRs = (pData["priceRs"] as num?)?.toInt() ?? 0;
        final qty = (pData["qty"] as num?)?.toDouble() ?? 1.0;
        final unit = (pData["unit"] ?? "pcs").toString();

        final baseQty = (pData["baseQty"] as num?)?.toDouble() ?? qty;
        final baseUnit = (pData["baseUnit"] ?? unit).toString();

        final pricePerBase =
            (pData["pricePerBase"] as num?)?.toDouble() ??
            (baseQty > 0 ? priceRs / baseQty : 0);

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
          sellerRating: (pData["sellerRating"] as num?)?.toDouble() ?? 0,
          distanceKm: (pData["distanceKm"] as num?)?.toDouble() ?? 0,
          locationName: (pData["locationName"] ?? "Unknown").toString(),
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

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StartNegotiationScreen(product: product),
          ),
        );
      },
    );
  }

  static String _formatTime(dynamic ts) {
    if (ts == null) return "";
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    // Hive cached might store string
    if (ts is String) {
      final dt = DateTime.tryParse(ts);
      if (dt != null) {
        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }
    }
    return "";
  }
}

class _OfferTile extends StatelessWidget {
  final String productId;
  final String productTitle;
  final String lastMessage;
  final String timeText;
  final String cachedImageUrl; // ✅ optional
  final VoidCallback onOpen;

  const _OfferTile({
    required this.productId,
    required this.productTitle,
    required this.lastMessage,
    required this.timeText,
    required this.onOpen,
    this.cachedImageUrl = "",
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
            _ProductThumb(productId: productId, cachedImageUrl: cachedImageUrl),
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
  final String cachedImageUrl;

  const _ProductThumb({required this.productId, this.cachedImageUrl = ""});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 58,
        height: 58,
        child: cachedImageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: cachedImageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _ph(),
                errorWidget: (_, __, ___) => _err(),
              )
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection("products")
                    .doc(productId)
                    .snapshots(),
                builder: (context, snap) {
                  final img = snap.data?.data()?["imageUrl"]?.toString() ?? "";
                  if (img.isEmpty) {
                    return _empty();
                  }
                  return CachedNetworkImage(
                    imageUrl: img,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _ph(),
                    errorWidget: (_, __, ___) => _err(),
                  );
                },
              ),
      ),
    );
  }

  Widget _ph() => Container(
    color: const Color(0xFFE5E7EB),
    alignment: Alignment.center,
    child: const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  Widget _err() => Container(
    color: const Color(0xFFE5E7EB),
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image, color: Colors.black45),
  );

  Widget _empty() => Container(
    color: const Color(0xFFE5E7EB),
    alignment: Alignment.center,
    child: const Icon(Icons.image, color: Colors.black45),
  );
}

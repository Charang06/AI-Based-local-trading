import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product.dart';

class StartNegotiationScreen extends StatefulWidget {
  final Product product;
  const StartNegotiationScreen({super.key, required this.product});

  @override
  State<StartNegotiationScreen> createState() => _StartNegotiationScreenState();
}

class _StartNegotiationScreenState extends State<StartNegotiationScreen> {
  final TextEditingController _msg = TextEditingController();
  bool _sending = false;

  String? _negotiationId;
  late Future<String> _initFuture;

  // cached IDs
  String _sellerId = "";
  String _buyerId = "";

  @override
  void initState() {
    super.initState();
    _initFuture = _ensureNegotiationNoRead();
  }

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  // negotiations/{productId}_{minUid}_{maxUid}
  String _buildNegotiationId({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) {
    final a = buyerId.compareTo(sellerId) <= 0 ? buyerId : sellerId;
    final b = buyerId.compareTo(sellerId) <= 0 ? sellerId : buyerId;
    return "${productId}_${a}_$b";
  }

  DocumentReference<Map<String, dynamic>> _negDoc(String id) {
    return FirebaseFirestore.instance.collection("negotiations").doc(id);
  }

  CollectionReference<Map<String, dynamic>> _msgCol(String id) {
    return _negDoc(id).collection("messages");
  }

  int? _extractOfferRs(String text) {
    // accept 2-7 digit numbers (avoid single digit noise)
    final cleaned = text.replaceAll(',', '');
    final m = RegExp(r'\b(\d{2,7})\b').firstMatch(cleaned);
    if (m == null) return null;
    final v = int.tryParse(m.group(1) ?? "");
    if (v == null || v <= 0) return null;
    return v;
  }

  int _roundNice(int v) {
    if (v <= 0) return 0;
    return ((v / 10).round() * 10);
  }

  /// ✅ IMPORTANT FIX:
  /// DO NOT read negotiations/{id} using get() before create,
  /// because your rules deny reading non-existing docs.
  ///
  /// We ONLY read products/{productId} to get sellerId,
  /// then do a single set(merge:true) which:
  /// - Creates if not exists (passes create rule)
  /// - Updates if exists (only changes allowed fields)
  Future<String> _ensureNegotiationNoRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("Not logged in");

    // Read sellerId from products/{productId}
    final productSnap = await FirebaseFirestore.instance
        .collection("products")
        .doc(widget.product.id)
        .get();

    final data = productSnap.data() ?? {};
    final sellerId = (data["sellerId"] ?? "").toString();

    if (sellerId.isEmpty) {
      throw Exception("sellerId missing in product");
    }

    if (uid == sellerId) {
      throw Exception("Seller cannot start negotiation here");
    }

    final buyerId = uid;

    final negotiationId = _buildNegotiationId(
      productId: widget.product.id,
      buyerId: buyerId,
      sellerId: sellerId,
    );

    final ref = FirebaseFirestore.instance
        .collection("negotiations")
        .doc(negotiationId);

    final snap = await ref.get();

    if (!snap.exists) {
      // ✅ CREATE negotiation (allowed by rules)
      await ref.set({
        "productId": widget.product.id,
        "productTitle": widget.product.title,
        "buyerId": buyerId,
        "sellerId": sellerId,
        "participants": [buyerId, sellerId],

        "status": "pending",

        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),

        "lastMessage": "",
        "lastOfferRs": 0,
        "lastOfferBy": "",
        "round": 0,

        "hasUnreadForSeller": false,
        "hasUnreadForBuyer": false,

        "sellerPriceRs": widget.product.priceRs,
        "marketLow": widget.product.marketLow,
        "marketHigh": widget.product.marketHigh,
      });
    } else {
      // ✅ ONLY update allowed keys (to satisfy rules)
      await ref.set({
        "updatedAt": FieldValue.serverTimestamp(),
        "hasUnreadForBuyer": false,
      }, SetOptions(merge: true));
    }

    _negotiationId = negotiationId;
    _sellerId = sellerId;
    _buyerId = buyerId;

    return negotiationId;
  }

  Future<void> _sendMessage({String? overrideText}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final id = _negotiationId;
    if (id == null) return;

    final raw = (overrideText ?? _msg.text).trim();
    if (raw.isEmpty) return;

    final offerRs = _extractOfferRs(raw);
    final isOffer = offerRs != null;

    // normalize message text for offers
    final text = isOffer ? "Offer: Rs $offerRs" : raw;

    setState(() => _sending = true);
    try {
      // 1) add buyer message (senderId MUST be auth.uid - your rules require that)
      await _msgCol(id).add({
        "text": text,
        "senderId": uid,
        "senderRole": "buyer",
        "createdAt": FieldValue.serverTimestamp(),
        "offerRs": offerRs ?? 0,
        "type": isOffer ? "offer" : "text",
      });

      // 2) update negotiation summary + unread for seller
      final update = <String, dynamic>{
        "lastMessage": text,
        "updatedAt": FieldValue.serverTimestamp(),
        "hasUnreadForSeller": true,
        "hasUnreadForBuyer": false,
      };

      if (isOffer) {
        update["lastOfferRs"] = offerRs;
        update["lastOfferBy"] = "buyer";
      }

      await _negDoc(id).set(update, SetOptions(merge: true));

      _msg.clear();

      // ✅ NO BOT HERE (Option 1)
      // Bot reply must run only on seller device in OfferDetailScreen listener.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Send failed: $e")));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _quickBtn(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: _sending ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ),
    );
  }

  Widget _bubble({
    required bool me,
    required String text,
    required String role, // buyer/seller/bot
    required int offerRs,
  }) {
    final isOffer = offerRs > 0 || text.toLowerCase().startsWith("offer:");
    final isBot = role == "bot";

    final bg = isBot
        ? const Color(0xFFF3E8FF)
        : (me ? const Color(0xFF2A7BF4) : const Color(0xFFF3F4F6));

    final fg = me ? Colors.white : Colors.black87;

    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 290),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: isOffer
              ? Border.all(
                  color: me
                      ? Colors.white.withValues(alpha: 0.55)
                      : Colors.black.withValues(alpha: 0.08),
                )
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isBot ? Colors.black87 : fg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Negotiate • ${widget.product.title}"),
          backgroundColor: const Color(0xFF2A7BF4),
        ),
        body: const Center(child: Text("Please login first.")),
      );
    }

    return FutureBuilder<String>(
      future: _initFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Negotiate • ${widget.product.title}"),
              backgroundColor: const Color(0xFF2A7BF4),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Negotiate • ${widget.product.title}"),
              backgroundColor: const Color(0xFF2A7BF4),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Error:\n${snap.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final negotiationId = snap.data!;
        _negotiationId = negotiationId;

        final ask = widget.product.priceRs;
        final ai = widget.product.aiPriceRs;
        final offer85 = _roundNice((ask * 0.85).round());
        final offer90 = _roundNice((ask * 0.90).round());
        final offer95 = _roundNice((ask * 0.95).round());

        // optional AI-offer button (if AI exists)
        final aiOffer = ai > 0 ? _roundNice((ai * 0.92).round()) : 0;

        return Scaffold(
          appBar: AppBar(
            title: Text("Negotiate • ${widget.product.title}"),
            backgroundColor: const Color(0xFF2A7BF4),
          ),
          body: Column(
            children: [
              // deal header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFF3F4F6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Asking: Rs $ask${ai > 0 ? "  •  AI: Rs $ai" : ""}",
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _quickBtn(
                          "Offer Rs $offer85",
                          () => _sendMessage(overrideText: "Offer Rs $offer85"),
                        ),
                        _quickBtn(
                          "Offer Rs $offer90",
                          () => _sendMessage(overrideText: "Offer Rs $offer90"),
                        ),
                        _quickBtn(
                          "Offer Rs $offer95",
                          () => _sendMessage(overrideText: "Offer Rs $offer95"),
                        ),
                        if (aiOffer > 0)
                          _quickBtn(
                            "AI Offer Rs $aiOffer",
                            () =>
                                _sendMessage(overrideText: "Offer Rs $aiOffer"),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // messages
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _msgCol(
                    negotiationId,
                  ).orderBy("createdAt", descending: true).snapshots(),
                  builder: (context, msgSnap) {
                    if (msgSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (msgSnap.hasError) {
                      return Center(child: Text("Error: ${msgSnap.error}"));
                    }

                    final docs = msgSnap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No messages yet.\nSend your first offer!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      reverse: true,
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final d = docs[i].data();
                        final text = (d["text"] ?? "").toString();
                        final senderId = (d["senderId"] ?? "").toString();
                        final role = (d["senderRole"] ?? "").toString();
                        final offerRs = (d["offerRs"] as num?)?.toInt() ?? 0;

                        final me = senderId == user.uid;

                        return _bubble(
                          me: me,
                          text: text,
                          role: role,
                          offerRs: offerRs,
                        );
                      },
                    );
                  },
                ),
              ),

              // input
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msg,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          if (_sending) return;
                          _sendMessage();
                        },
                        decoration: InputDecoration(
                          hintText: "Type message or offer (e.g., 15000)...",
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _sending ? null : _sendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

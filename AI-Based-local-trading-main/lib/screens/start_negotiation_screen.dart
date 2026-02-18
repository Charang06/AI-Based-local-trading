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

  // cached IDs for unread flags
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
    final m = RegExp(r'(\d{1,7})').firstMatch(text.replaceAll(',', ''));
    if (m == null) return null;
    final v = int.tryParse(m.group(1) ?? "");
    if (v == null || v <= 0) return null;
    return v;
  }

  int _roundNice(int v) {
    if (v <= 0) return 0;
    return ((v / 10).round() * 10);
  }

  /// ✅ KEY FIX: DO NOT read negotiation doc before create.
  /// We only read products/{productId} to get sellerId (allowed by your rules).
  Future<String> _ensureNegotiationNoRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("Not logged in");

    // Read sellerId from products/{productId}
    final productSnap = await FirebaseFirestore.instance
        .collection("products")
        .doc(widget.product.id)
        .get();

    final pData = productSnap.data() ?? {};
    final sellerId = (pData["sellerId"] ?? "").toString();

    if (sellerId.isEmpty) {
      throw Exception(
        "Missing sellerId in products/${widget.product.id}.\n"
        "Fix: when posting product, store sellerId = currentUser.uid",
      );
    }

    // Prevent seller opening buyer negotiation screen
    if (uid == sellerId) {
      throw Exception("You are the seller. Open this chat from Manage Offers.");
    }

    final buyerId = uid;
    final negotiationId = _buildNegotiationId(
      productId: widget.product.id,
      buyerId: buyerId,
      sellerId: sellerId,
    );

    // ✅ Create doc WITHOUT get()
    // Using merge:true so it works even if already exists.
    await _negDoc(negotiationId).set({
      "productId": widget.product.id,
      "productTitle": widget.product.title,
      "buyerId": buyerId,
      "sellerId": sellerId,
      "participants": [buyerId, sellerId],

      // default values
      "status": "pending",
      "lastMessage": "",
      "updatedAt": FieldValue.serverTimestamp(),
      "createdAt": FieldValue.serverTimestamp(),

      // unread flags
      "hasUnreadForSeller": false,
      "hasUnreadForBuyer": false,

      // offer tracking (optional)
      "lastOfferRs": 0,
      "lastOfferBy": "",
    }, SetOptions(merge: true));

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

    final text = (overrideText ?? _msg.text).trim();
    if (text.isEmpty) return;

    final offerRs = _extractOfferRs(text);

    setState(() => _sending = true);
    try {
      // add message
      await _msgCol(id).add({
        "text": text,
        "senderId": uid,
        "senderRole": "buyer",
        "createdAt": FieldValue.serverTimestamp(),
        "offerRs": offerRs ?? 0,
        "type": offerRs != null ? "offer" : "text",
      });

      // update parent doc (unread + lastMessage)
      final update = <String, dynamic>{
        "lastMessage": text,
        "updatedAt": FieldValue.serverTimestamp(),
        "hasUnreadForSeller": true,
      };

      if (offerRs != null) {
        update["lastOfferRs"] = offerRs;
        update["lastOfferBy"] = uid;
      }

      await _negDoc(id).set(update, SetOptions(merge: true));
      _msg.clear();
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
    bool isOffer = false,
  }) {
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: me ? const Color(0xFF2A7BF4) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: isOffer
              ? Border.all(
                  color: me
                      ? Colors.white.withValues(alpha: 0.55)
                      : Colors.black.withValues(alpha: 0.10),
                )
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: me ? Colors.white : Colors.black87,
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

        return Scaffold(
          appBar: AppBar(
            title: Text("Negotiate • ${widget.product.title}"),
            backgroundColor: const Color(0xFF2A7BF4),
          ),
          body: Column(
            children: [
              // quick offers card
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

                    // ✅ Don't spam writes in build.
                    // If you want "mark as read", do it once in init after screen open,
                    // or using a button. For now we keep it simple: no auto write here.

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      reverse: true,
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final d = docs[i].data();
                        final text = (d["text"] ?? "").toString();
                        final senderId = (d["senderId"] ?? "").toString();
                        final me = senderId == user.uid;
                        final offerRs = (d["offerRs"] as num?)?.toInt() ?? 0;

                        return _bubble(
                          me: me,
                          text: text,
                          isOffer: offerRs > 0,
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
                          hintText: "Type message or offer (e.g., Rs 150)...",
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/negotiation_bot.dart';

class OfferDetailScreen extends StatefulWidget {
  final String negotiationId;
  final String productTitle;
  final bool amSeller;
  final String? otherUserId;

  const OfferDetailScreen({
    super.key,
    required this.negotiationId,
    required this.productTitle,
    required this.amSeller,
    this.otherUserId,
  });

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  final TextEditingController _msg = TextEditingController();
  bool _sending = false;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _botSub;

  DocumentReference<Map<String, dynamic>> get _negDoc => FirebaseFirestore
      .instance
      .collection("negotiations")
      .doc(widget.negotiationId);

  CollectionReference<Map<String, dynamic>> get _msgCol =>
      _negDoc.collection("messages");

  @override
  void initState() {
    super.initState();

    // ✅ Only seller device runs bot auto-reply listener
    if (widget.amSeller) {
      _startBotListener();
    }
  }

  @override
  void dispose() {
    _botSub?.cancel();
    _msg.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------
  int? _extractOfferRs(String text) {
    final m = RegExp(r'(\d{1,9})').firstMatch(text.replaceAll(',', ''));
    if (m == null) return null;
    final v = int.tryParse(m.group(1) ?? "");
    if (v == null || v <= 0) return null;
    return v;
  }

  String _formatTime(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      return "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    }
    return "";
  }

  // ---------- BOT LISTENER (seller only) ----------
  void _startBotListener() {
    _botSub = _msgCol
        .orderBy("createdAt", descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) async {
          if (!mounted) return;
          if (snap.docs.isEmpty) return;

          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) return;

          final last = snap.docs.first.data();

          // If last message is NOT from buyer => do nothing
          final senderRole = (last["senderRole"] ?? "").toString();
          if (senderRole != "buyer") return;

          // If last message is not offer => do nothing
          final type = (last["type"] ?? "").toString();
          final buyerOffer = (last["offerRs"] as num?)?.toInt() ?? 0;
          if (type != "offer" || buyerOffer <= 0) return;

          // Prevent duplicate bot replies:
          // check negotiation doc lastBotOfferRs
          final negSnap = await _negDoc.get();
          final neg = negSnap.data() ?? {};
          final lastBotOfferRs = (neg["lastBotOfferRs"] as num?)?.toInt() ?? 0;
          if (lastBotOfferRs == buyerOffer) return;

          await _botReplyAsSeller(sellerUid: uid, buyerOffer: buyerOffer);
        });
  }

  Future<void> _botReplyAsSeller({
    required String sellerUid,
    required int buyerOffer,
  }) async {
    final snap = await _negDoc.get();
    final data = snap.data() ?? {};

    final sellerPrice = (data["sellerPriceRs"] as num?)?.toInt() ?? 0;
    final round = (data["round"] as num?)?.toInt() ?? 0;

    final marketLow = (data["marketLow"] as num?)?.toInt() ?? 0;
    final marketHigh = (data["marketHigh"] as num?)?.toInt() ?? 0;

    final decision = NegotiationBot.decide(
      sellerPriceRs: sellerPrice > 0 ? sellerPrice : 200,
      buyerOfferRs: buyerOffer,
      marketLow: marketLow,
      marketHigh: marketHigh,
      round: round,
    );

    final update = <String, dynamic>{
      "updatedAt": FieldValue.serverTimestamp(),
      "round": round + 1,
      "lastOfferRs": buyerOffer,
      "lastOfferBy": "buyer",
      "lastBotOfferRs": buyerOffer, // ✅ prevents duplicate bot replies
      "lastMessage": decision.text,
    };

    if (decision.type == "counter") {
      update["lastCounterRs"] = decision.counterOfferRs ?? 0;
      update["status"] = "pending";
    } else if (decision.type == "accept") {
      update["status"] = "accepted";
      update["acceptedPriceRs"] = buyerOffer;
    } else if (decision.type == "reject") {
      update["status"] = "rejected";
    }

    await _negDoc.set(update, SetOptions(merge: true));
  }

  // ---------- SEND (buyer/seller normal message) ----------
  Future<void> _send() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final text = _msg.text.trim();
    if (uid == null || text.isEmpty) return;

    setState(() => _sending = true);

    try {
      final offer = _extractOfferRs(text);
      final isOffer = offer != null;

      await _msgCol.add({
        "text": isOffer ? "Offer: Rs $offer" : text,
        "senderId": uid,
        "senderRole": widget.amSeller ? "seller" : "buyer",
        "type": isOffer ? "offer" : "text",
        "offerRs": offer ?? 0,
        "createdAt": FieldValue.serverTimestamp(),
      });

      await _negDoc.set({
        "lastMessage": isOffer ? "Offer: Rs $offer" : text,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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

  // ---------- Seller accept/reject ----------
  Future<void> _setStatus(String status) async {
    try {
      if (!widget.amSeller) return;

      await _negDoc.set({
        "status": status,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Offer marked as $status")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Offer • ${widget.productTitle}"),
        backgroundColor: const Color(0xFF2A7BF4),
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _negDoc.snapshots(),
            builder: (context, snap) {
              final data = snap.data?.data() ?? {};
              final status = (data["status"] ?? "pending").toString();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFF3F4F6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Status: $status",
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (widget.amSeller) ...[
                      TextButton(
                        onPressed: status == "accepted"
                            ? null
                            : () => _setStatus("accepted"),
                        child: const Text("Accept"),
                      ),
                      TextButton(
                        onPressed: status == "rejected"
                            ? null
                            : () => _setStatus("rejected"),
                        child: const Text("Reject"),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _msgCol
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text("Error: ${snap.error}"));
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages yet.\nSend your first offer!",
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final text = (d["text"] ?? "").toString();
                    final senderId = (d["senderId"] ?? "").toString();
                    final senderRole = (d["senderRole"] ?? "").toString();
                    final time = _formatTime(d["createdAt"]);

                    final me = (uid != null && senderId == uid);
                    final isBot = senderRole == "bot";

                    return Align(
                      alignment: me
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 290),
                        decoration: BoxDecoration(
                          color: isBot
                              ? const Color(0xFFF3E8FF)
                              : (me
                                    ? const Color(0xFF2A7BF4)
                                    : const Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: me
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: TextStyle(
                                color: me ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10,
                                color: me ? Colors.white70 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

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
                    onSubmitted: (_) => _sending ? null : _send(),
                    decoration: InputDecoration(
                      hintText: widget.amSeller
                          ? "Type message..."
                          : "Type offer (e.g. 150) or message...",
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
                    onPressed: _sending ? null : _send,
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
  }
}

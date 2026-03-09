import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_language.dart';
import '../services/negotiation_bot.dart';
import '../services/voice_assistant.dart';

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

  bool _botVoiceOn = true;
  List<Map<String, dynamic>> _latestMessages = const [];

  // local dedupe for seller bot
  int _lastHandledBuyerOffer = -1;

  DocumentReference<Map<String, dynamic>> get _negDoc => FirebaseFirestore
      .instance
      .collection("negotiations")
      .doc(widget.negotiationId);

  CollectionReference<Map<String, dynamic>> get _msgCol =>
      _negDoc.collection("messages");

  @override
  void initState() {
    super.initState();
    _markOpened();

    if (widget.amSeller) {
      _startBotListener();
    }
  }

  @override
  void dispose() {
    _botSub?.cancel();
    _msg.dispose();
    VoiceAssistant.instance.stop();
    super.dispose();
  }

  Future<void> _markOpened() async {
    try {
      await _negDoc.set({
        "updatedAt": FieldValue.serverTimestamp(),
        if (widget.amSeller) "hasUnreadForSeller": false,
        if (!widget.amSeller) "hasUnreadForBuyer": false,
      }, SetOptions(merge: true));
    } catch (_) {
      // ignore
    }
  }

  // =========================
  // ✅ Translations
  // =========================
  String _t(AppLang lang, String key) {
    const en = {
      "title": "Offer",
      "status": "Status",
      "pending": "pending",
      "accepted": "accepted",
      "rejected": "rejected",
      "accept": "Accept",
      "reject": "Reject",
      "no_messages": "No messages yet.\nSend your first offer!",
      "hint_buyer": "Type offer (e.g. 150) or message...",
      "hint_seller": "Type message...",
      "send_failed": "Send failed",
      "update_failed": "Update failed",
      "marked_as": "Offer marked as",
      "help": "Help",
      "stop": "Stop",
      "read": "Read",
      "bot_voice": "Bot voice",
      "help_text":
          "This is the offer chat. Type a number to send an offer. Seller can accept or reject. Use Read to hear recent messages.",
      "read_nothing": "No messages to read.",
    };

    const si = {
      "title": "යෝජනා",
      "status": "තත්වය",
      "pending": "පැවැති",
      "accepted": "අනුමත",
      "rejected": "ප්‍රතික්ෂේප",
      "accept": "අනුමත කරන්න",
      "reject": "ප්‍රතික්ෂේප කරන්න",
      "no_messages": "තවම පණිවිඩ නැහැ.\nපළමු යෝජනාව යවන්න!",
      "hint_buyer": "යෝජනාව (උදා: 150) හෝ පණිවිඩයක් ලියන්න...",
      "hint_seller": "පණිවිඩය ලියන්න...",
      "send_failed": "යැවීම අසාර්ථකයි",
      "update_failed": "යාවත්කාලීන කිරීම අසාර්ථකයි",
      "marked_as": "යෝජනාව තත්වය",
      "help": "උදව්",
      "stop": "නවතන්න",
      "read": "කියවන්න",
      "bot_voice": "බොට් හඬ",
      "help_text":
          "මෙය යෝජනා කතාබස් තිරයයි. අංකයක් ලියලා යෝජනාවක් යවන්න. විකුණුම්කරුට අනුමත/ප්‍රතික්ෂේප කළ හැක. ‘කියවන්න’ බොත්තමෙන් පණිවිඩ අසන්න.",
      "read_nothing": "කියවීමට පණිවිඩ නැහැ.",
    };

    const ta = {
      "title": "சலுகை",
      "status": "நிலை",
      "pending": "நிலுவை",
      "accepted": "ஏற்றுக்கொண்டது",
      "rejected": "நிராகரிக்கப்பட்டது",
      "accept": "ஏற்றுக்கொள்",
      "reject": "நிராகரி",
      "no_messages": "இன்னும் செய்தி இல்லை.\nமுதல் சலுகையை அனுப்பவும்!",
      "hint_buyer": "சலுகை (எ.கா: 150) அல்லது செய்தி எழுதவும்...",
      "hint_seller": "செய்தி எழுதவும்...",
      "send_failed": "அனுப்ப முடியவில்லை",
      "update_failed": "புதுப்பிப்பு தோல்வி",
      "marked_as": "சலுகை நிலை",
      "help": "உதவி",
      "stop": "நிறுத்து",
      "read": "படிக்க",
      "bot_voice": "பாட் குரல்",
      "help_text":
          "இது சலுகை உரையாடல். எண்ணை எழுதினால் சலுகையாக அனுப்பப்படும். விற்பனையாளர் ஏற்ற/நிராகரிக்கலாம். ‘படிக்க’ பொத்தானால் சமீப செய்திகளை கேட்கலாம்.",
      "read_nothing": "படிக்க செய்திகள் இல்லை.",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  String _statusLabel(AppLang lang, String status) {
    if (status == "accepted") return _t(lang, "accepted");
    if (status == "rejected") return _t(lang, "rejected");
    return _t(lang, "pending");
  }

  String _langCode(AppLang lang) {
    if (lang == AppLang.si) return "si-LK";
    if (lang == AppLang.ta) return "ta-IN";
    return "en-US";
  }

  // =========================
  // ✅ Helpers
  // =========================
  int? _extractOfferRs(String text) {
    final m = RegExp(r'\b(\d{2,7})\b').firstMatch(text.replaceAll(',', ''));
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

  // =========================
  // ✅ Voice actions
  // =========================
  Future<void> _speakHelp(AppLang lang) async {
    await VoiceAssistant.instance.init(languageCode: _langCode(lang));
    await VoiceAssistant.instance.speak(_t(lang, "help_text"));
  }

  Future<void> _readRecentMessages(AppLang lang) async {
    await VoiceAssistant.instance.init(languageCode: _langCode(lang));

    if (_latestMessages.isEmpty) {
      await VoiceAssistant.instance.speak(_t(lang, "read_nothing"));
      return;
    }

    final take = _latestMessages.take(3).toList();
    String text = "";

    for (final m in take.reversed) {
      final senderRole = (m["senderRole"] ?? "").toString();
      final msgText = (m["text"] ?? "").toString();

      if (lang == AppLang.si) {
        final who = (senderRole == "seller")
            ? "විකුණුම්කරු"
            : (senderRole == "buyer")
            ? "ගැනුම්කරු"
            : "බොට්";
        text += "$who: $msgText. ";
      } else if (lang == AppLang.ta) {
        final who = (senderRole == "seller")
            ? "விற்பனையாளர்"
            : (senderRole == "buyer")
            ? "வாங்குபவர்"
            : "பாட்";
        text += "$who: $msgText. ";
      } else {
        final who = (senderRole == "seller")
            ? "Seller"
            : (senderRole == "buyer")
            ? "Buyer"
            : "Bot";
        text += "$who says: $msgText. ";
      }
    }

    await VoiceAssistant.instance.speak(text);
  }

  // =========================
  // ✅ BOT LISTENER (seller only)
  // =========================
  void _startBotListener() {
    _botSub = _msgCol
        .orderBy("createdAt", descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) async {
          if (!mounted) return;
          if (snap.docs.isEmpty) return;

          final sellerUid = FirebaseAuth.instance.currentUser?.uid;
          if (sellerUid == null) return;

          final last = snap.docs.first.data();

          final senderRole = (last["senderRole"] ?? "").toString();
          if (senderRole != "buyer") return;

          final type = (last["type"] ?? "").toString();
          final buyerOffer = (last["offerRs"] as num?)?.toInt() ?? 0;
          if (type != "offer" || buyerOffer <= 0) return;

          if (buyerOffer == _lastHandledBuyerOffer) return;
          _lastHandledBuyerOffer = buyerOffer;

          await _botReplyAsSeller(sellerUid: sellerUid, buyerOffer: buyerOffer);
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

    // ✅ common update: allowed by your current rules
    final commonUpdate = <String, dynamic>{
      "updatedAt": FieldValue.serverTimestamp(),
      "round": round + 1,
      "lastOfferRs": buyerOffer,
      "lastOfferBy": "buyer",
      "lastMessage": decision.text,
      "hasUnreadForSeller": false,
      "hasUnreadForBuyer": true,
    };

    if (decision.type == "counter") {
      commonUpdate["lastCounterRs"] = decision.counterOfferRs ?? 0;
    }

    await _negDoc.set(commonUpdate, SetOptions(merge: true));

    // ✅ status update separately for strict rules
    if (decision.type == "accept") {
      await _negDoc.set({
        "status": "accepted",
        "acceptedPriceRs": buyerOffer,
        "updatedAt": FieldValue.serverTimestamp(),
        "hasUnreadForBuyer": true,
        "hasUnreadForSeller": false,
      }, SetOptions(merge: true));
    } else if (decision.type == "reject") {
      await _negDoc.set({
        "status": "rejected",
        "updatedAt": FieldValue.serverTimestamp(),
        "hasUnreadForBuyer": true,
        "hasUnreadForSeller": false,
      }, SetOptions(merge: true));
    }

    final botType = (decision.type == "counter") ? "offer" : "text";
    final botOfferRs = (decision.type == "counter")
        ? (decision.counterOfferRs ?? 0)
        : 0;

    await _msgCol.add({
      "text": decision.text,
      "senderId": sellerUid, // must be auth uid
      "senderRole": "bot",
      "type": botType,
      "offerRs": botOfferRs,
      "createdAt": FieldValue.serverTimestamp(),
    });

    if (!mounted || !_botVoiceOn) return;
    final lang = AppLanguage.current.value;
    await VoiceAssistant.instance.init(languageCode: _langCode(lang));
    await VoiceAssistant.instance.speak(decision.text);
  }

  // =========================
  // ✅ SEND message / offer
  // =========================
  Future<void> _send() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final text = _msg.text.trim();
    if (uid == null || text.isEmpty) return;

    setState(() => _sending = true);

    try {
      final offer = _extractOfferRs(text);
      final isOffer = offer != null;
      final sendText = isOffer ? "Offer: Rs $offer" : text;

      await _msgCol.add({
        "text": sendText,
        "senderId": uid,
        "senderRole": widget.amSeller ? "seller" : "buyer",
        "type": isOffer ? "offer" : "text",
        "offerRs": offer ?? 0,
        "createdAt": FieldValue.serverTimestamp(),
      });

      await _negDoc.set({
        "lastMessage": sendText,
        "updatedAt": FieldValue.serverTimestamp(),
        "hasUnreadForSeller": widget.amSeller ? false : true,
        "hasUnreadForBuyer": widget.amSeller ? true : false,
        if (isOffer) "lastOfferRs": offer,
        if (isOffer) "lastOfferBy": widget.amSeller ? "seller" : "buyer",
      }, SetOptions(merge: true));

      _msg.clear();
    } catch (e) {
      if (!mounted) return;
      final lang = AppLanguage.current.value;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${_t(lang, "send_failed")}: $e")));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // =========================
  // ✅ Seller accept/reject
  // =========================
  Future<void> _setStatus(String status) async {
    try {
      if (!widget.amSeller) return;

      await _negDoc.set({
        "status": status,
        "updatedAt": FieldValue.serverTimestamp(),
        "hasUnreadForBuyer": true,
        "hasUnreadForSeller": false,
      }, SetOptions(merge: true));

      if (!mounted) return;
      final lang = AppLanguage.current.value;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${_t(lang, "marked_as")} $status")),
      );
    } catch (e) {
      if (!mounted) return;
      final lang = AppLanguage.current.value;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${_t(lang, "update_failed")}: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text("${_t(lang, "title")} • ${widget.productTitle}"),
            backgroundColor: const Color(0xFF2A7BF4),
            actions: [
              if (widget.amSeller)
                IconButton(
                  tooltip: _t(lang, "bot_voice"),
                  onPressed: () => setState(() => _botVoiceOn = !_botVoiceOn),
                  icon: Icon(
                    _botVoiceOn ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white,
                  ),
                ),
              IconButton(
                tooltip: _t(lang, "stop"),
                onPressed: () => VoiceAssistant.instance.stop(),
                icon: const Icon(Icons.stop, color: Colors.white),
              ),
              IconButton(
                tooltip: _t(lang, "help"),
                onPressed: () => _speakHelp(lang),
                icon: const Icon(Icons.help_outline, color: Colors.white),
              ),
              IconButton(
                tooltip: _t(lang, "read"),
                onPressed: () => _readRecentMessages(lang),
                icon: const Icon(Icons.record_voice_over, color: Colors.white),
              ),
            ],
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
                            "${_t(lang, "status")}: ${_statusLabel(lang, status)}",
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (widget.amSeller) ...[
                          TextButton(
                            onPressed: status == "accepted"
                                ? null
                                : () => _setStatus("accepted"),
                            child: Text(_t(lang, "accept")),
                          ),
                          TextButton(
                            onPressed: status == "rejected"
                                ? null
                                : () => _setStatus("rejected"),
                            child: Text(_t(lang, "reject")),
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
                      _latestMessages = const [];
                      return Center(
                        child: Text(
                          _t(lang, "no_messages"),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    _latestMessages = docs
                        .take(10)
                        .map((d) => d.data())
                        .toList(growable: false);

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
                      color: Colors.black.withOpacity(0.08),
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
                              ? _t(lang, "hint_seller")
                              : _t(lang, "hint_buyer"),
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
      },
    );
  }
}

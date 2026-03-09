import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_language.dart';
import '../services/voice_assistant.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  String tab = "pending"; // pending/accepted/rejected/completed/all

  // ✅ Voice: auto speak once
  bool _autoSpoken = false;

  // ✅ Voice: keep current visible list for "Read"
  List<_OrderRow> _currentOrders = const [];

  String _ttsLangCode(AppLang lang) {
    if (lang == AppLang.si) return "si-LK";
    if (lang == AppLang.ta) return "ta-IN";
    return "en-US";
  }

  String _t(AppLang lang, String key) {
    const en = {
      "title": "My Orders",
      "login_first": "Please login first.",
      "pending": "Pending",
      "accepted": "Accepted",
      "rejected": "Rejected",
      "done": "Done",
      "all": "All",
      "no_orders": "No orders found.",
      "accept": "Accept",
      "reject": "Reject",
      "mark_done": "Mark Completed",
      "help": "Help",
      "stop": "Stop",
      "read": "Read",
      "help_text":
          "This is Seller Orders. Use tabs to filter. Open an order to view details. If pending, you can accept or reject. If accepted, mark completed. Use Read to hear visible orders.",
      "status_pending": "Pending",
      "status_accepted": "Accepted",
      "status_rejected": "Rejected",
      "status_completed": "Done",
      "read_none": "No orders to read.",
      "updated": "Order marked as",
    };

    const si = {
      "title": "මගේ ඇණවුම්",
      "login_first": "කරුණාකර පළමුව ලොගින් වන්න.",
      "pending": "පැවතුණු",
      "accepted": "පිළිගත්",
      "rejected": "ප්‍රතික්ෂේප",
      "done": "අවසන්",
      "all": "සියල්ල",
      "no_orders": "ඇණවුම් නොමැත.",
      "accept": "පිළිගන්න",
      "reject": "ප්‍රතික්ෂේප කරන්න",
      "mark_done": "අවසන් ලෙස සලකුණු කරන්න",
      "help": "උදව්",
      "stop": "නවතන්න",
      "read": "කියවන්න",
      "help_text":
          "මෙය විකුණුම්කරුගේ ඇණවුම් තිරයයි. ටැබ් වලින් පෙරහන් කරන්න. Pending නම් පිළිගන්න/ප්‍රතික්ෂේප කරන්න. Accepted නම් අවසන් ලෙස සලකුණු කරන්න. Read බොත්තමෙන් පෙන්වෙන ඇණවුම් අසන්න.",
      "status_pending": "පැවතුණු",
      "status_accepted": "පිළිගත්",
      "status_rejected": "ප්‍රතික්ෂේප",
      "status_completed": "අවසන්",
      "read_none": "කියවීමට ඇණවුම් නොමැත.",
      "updated": "ඇණවුම තත්ත්වය",
    };

    const ta = {
      "title": "என் ஆர்டர்கள்",
      "login_first": "முதலில் உள்நுழையவும்.",
      "pending": "நிலுவை",
      "accepted": "ஏற்றுக்கொண்டது",
      "rejected": "நிராகரிக்கப்பட்டது",
      "done": "முடிந்தது",
      "all": "அனைத்து",
      "no_orders": "ஆர்டர்கள் இல்லை.",
      "accept": "ஏற்றுக்கொள்",
      "reject": "நிராகரி",
      "mark_done": "முடிந்தது என குறி",
      "help": "உதவி",
      "stop": "நிறுத்து",
      "read": "படிக்க",
      "help_text":
          "இது விற்பனையாளர் ஆர்டர் திரை. டாப்கள் மூலம் வடிகட்டு. Pending என்றால் ஏற்ற/நிராகரி. Accepted என்றால் முடிந்தது என குறி. Read மூலம் காணப்படும் ஆர்டர்களை கேட்கலாம்.",
      "status_pending": "நிலுவை",
      "status_accepted": "ஏற்றுக்கொண்டது",
      "status_rejected": "நிராகரிக்கப்பட்டது",
      "status_completed": "முடிந்தது",
      "read_none": "படிக்க ஆர்டர்கள் இல்லை.",
      "updated": "ஆர்டர் நிலை",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  String _statusLabel(AppLang lang, String status) {
    if (status == "accepted") return _t(lang, "status_accepted");
    if (status == "rejected") return _t(lang, "status_rejected");
    if (status == "completed") return _t(lang, "status_completed");
    return _t(lang, "status_pending");
  }

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
        "hasUnreadForBuyer": true,
        "hasUnreadForSeller": false,
      }, SetOptions(merge: true));

      if (!mounted) return;
      final lang = AppLanguage.current.value;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${_t(lang, "updated")} $status ✅")),
      );
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

  Future<void> _speakHelp(AppLang lang) async {
    await VoiceAssistant.instance.init(languageCode: _ttsLangCode(lang));
    await VoiceAssistant.instance.speak(_t(lang, "help_text"));
  }

  Future<void> _readVisibleOrders(AppLang lang) async {
    await VoiceAssistant.instance.init(languageCode: _ttsLangCode(lang));

    if (_currentOrders.isEmpty) {
      await VoiceAssistant.instance.speak(_t(lang, "read_none"));
      return;
    }

    final items = _currentOrders.take(5).toList();

    String text;
    if (lang == AppLang.si) {
      text = "පෙන්වෙන ඇණවුම්: ";
      for (final o in items) {
        text +=
            "${o.title}. තත්ත්වය ${_statusLabel(lang, o.status)}. මුළු මුදල රුපියල් ${o.totalRs}. ";
      }
    } else if (lang == AppLang.ta) {
      text = "காணப்படும் ஆர்டர்கள்: ";
      for (final o in items) {
        text +=
            "${o.title}. நிலை ${_statusLabel(lang, o.status)}. மொத்தம் ரூபாய் ${o.totalRs}. ";
      }
    } else {
      text = "Visible orders: ";
      for (final o in items) {
        text +=
            "${o.title}. Status ${_statusLabel(lang, o.status)}. Total Rs ${o.totalRs}. ";
      }
    }

    await VoiceAssistant.instance.speak(text);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _autoSpoken) return;
      _autoSpoken = true;

      final lang = AppLanguage.current.value;
      await _speakHelp(lang);
    });
  }

  @override
  void dispose() {
    VoiceAssistant.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          return Scaffold(body: Center(child: Text(_t(lang, "login_first"))));
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
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _t(lang, "title"),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        // ✅ Stop / Read / Help
                        _circleBtn(
                          icon: Icons.stop,
                          onTap: () => VoiceAssistant.instance.stop(),
                        ),
                        const SizedBox(width: 8),
                        _circleBtn(
                          icon: Icons.record_voice_over,
                          onTap: () => _readVisibleOrders(lang),
                        ),
                        const SizedBox(width: 8),
                        _circleBtn(
                          icon: Icons.volume_up,
                          onTap: () => _speakHelp(lang),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _tabs(lang),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: q.snapshots(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snap.hasError) {
                          return Center(child: Text("Error: ${snap.error}"));
                        }

                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          _currentOrders = const [];
                          return Center(child: Text(_t(lang, "no_orders")));
                        }

                        _currentOrders = docs
                            .map((doc) {
                              final d = doc.data();
                              final title = (d["productTitle"] ?? "Product")
                                  .toString();
                              final status = (d["status"] ?? "pending")
                                  .toString();
                              final totalRs =
                                  (d["totalRs"] as num?)?.toInt() ?? 0;
                              return _OrderRow(
                                title: title,
                                status: status,
                                totalRs: totalRs,
                              );
                            })
                            .toList(growable: false);

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final doc = docs[i];
                            final d = doc.data();

                            final status = (d["status"] ?? "pending")
                                .toString();
                            final productTitle =
                                (d["productTitle"] ?? "Product").toString();
                            final buyerName = (d["buyerName"] ?? "Buyer")
                                .toString();
                            final buyerPhone = (d["buyerPhone"] ?? "")
                                .toString();

                            final qty = (d["qty"] as num?)?.toDouble() ?? 1;
                            final unit = (d["unit"] ?? "unit").toString();
                            final priceRs =
                                (d["priceRs"] as num?)?.toInt() ?? 0;

                            final totalRs =
                                (d["totalRs"] as num?)?.toInt() ??
                                (priceRs * qty).round();
                            final address = (d["deliveryAddress"] ?? "")
                                .toString();
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                                                      fontWeight:
                                                          FontWeight.w900,
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
                                                        fontWeight:
                                                            FontWeight.w900,
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
                                      _statusPill(status, lang),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            text: _t(lang, "accept"),
                                            color: const Color(0xFF22C55E),
                                            onTap: () =>
                                                _setStatus(doc.id, "accepted"),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _actionBtn(
                                            text: _t(lang, "reject"),
                                            color: const Color(0xFFEF4444),
                                            onTap: () =>
                                                _setStatus(doc.id, "rejected"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else if (status == "accepted") ...[
                                    _actionBtn(
                                      text: _t(lang, "mark_done"),
                                      color: const Color(0xFF2A7BF4),
                                      onTap: () =>
                                          _setStatus(doc.id, "completed"),
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
      },
    );
  }

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _tabs(AppLang lang) {
    return Row(
      children: [
        Expanded(child: _tabBtn(_t(lang, "pending"), "pending")),
        const SizedBox(width: 8),
        Expanded(child: _tabBtn(_t(lang, "accepted"), "accepted")),
        const SizedBox(width: 8),
        Expanded(child: _tabBtn(_t(lang, "rejected"), "rejected")),
        const SizedBox(width: 8),
        Expanded(child: _tabBtn(_t(lang, "done"), "completed")),
        const SizedBox(width: 8),
        Expanded(child: _tabBtn(_t(lang, "all"), "all")),
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

  Widget _statusPill(String status, AppLang lang) {
    if (status == "accepted") {
      return _pill(
        _t(lang, "status_accepted"),
        const Color(0xFFD9FFE6),
        const Color(0xFF16A34A),
      );
    }
    if (status == "rejected") {
      return _pill(
        _t(lang, "status_rejected"),
        const Color(0xFFFFECEC),
        const Color(0xFFEF4444),
      );
    }
    if (status == "completed") {
      return _pill(
        _t(lang, "status_completed"),
        const Color(0xFFEAF7FF),
        const Color(0xFF2A7BF4),
      );
    }
    return _pill(
      _t(lang, "status_pending"),
      const Color(0xFFFFF7D6),
      const Color(0xFFB45309),
    );
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

class _OrderRow {
  final String title;
  final String status;
  final int totalRs;

  const _OrderRow({
    required this.title,
    required this.status,
    required this.totalRs,
  });
}

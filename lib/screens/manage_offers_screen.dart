import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_language.dart';
import '../services/voice_assistant.dart';
import 'offer_detail_screen.dart';

class ManageOffersScreen extends StatefulWidget {
  const ManageOffersScreen({super.key});

  @override
  State<ManageOffersScreen> createState() => _ManageOffersScreenState();
}

class _ManageOffersScreenState extends State<ManageOffersScreen> {
  // pending / accepted / rejected / all
  String tab = "pending";

  bool _autoSpoken = false;

  bool _noOffersSpoken = false;
  String _noOffersSig = "";

  List<_OfferRow> _currentOffers = const [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _autoSpoken) return;
      _autoSpoken = true;

      final lang = AppLanguage.current.value;
      await _speakOffersGuide(lang);
    });
  }

  @override
  void dispose() {
    VoiceAssistant.instance.stop();
    super.dispose();
  }

  String _t(AppLang lang, String key) {
    const en = {
      "title": "Manage Offers",
      "login_first": "Please login first.",
      "pending": "Pending",
      "accepted": "Accepted",
      "rejected": "Rejected",
      "all": "All",
      "filters": "Tabs Help",
      "no_offers": "No offers found.",
      "tap_open": "Tap to open offer chat",
      "buyer": "Buyer",
      "help": "Help",
      "stop": "Stop",
      "read": "Read",
      "filters_help":
          "Use tabs: Pending, Accepted, Rejected, or All. Tap any offer card to open the chat.",
      "status_pending": "Pending",
      "status_accepted": "Accepted",
      "status_rejected": "Rejected",
      "read_none": "There are no offers to read.",
    };

    const si = {
      "title": "යෝජනා කළමනාකරණය",
      "login_first": "කරුණාකර පළමුව ලොගින් වන්න.",
      "pending": "පැවතුණු",
      "accepted": "පිළිගත්",
      "rejected": "ප්‍රතික්ෂේප",
      "all": "සියල්ල",
      "filters": "ටැබ් උදව්",
      "no_offers": "යෝජනා නොමැත.",
      "tap_open": "චැට් එක විවෘත කිරීමට ඔබන්න",
      "buyer": "ගැනුම්කරු",
      "help": "උදව්",
      "stop": "නවතන්න",
      "read": "කියවන්න",
      "filters_help":
          "ටැබ් භාවිතා කරන්න: පැවතුණු, පිළිගත්, ප්‍රතික්ෂේප, හෝ සියල්ල. කාඩ් එකක් ඔබා චැට් එක විවෘත කරන්න.",
      "status_pending": "පැවතුණු",
      "status_accepted": "පිළිගත්",
      "status_rejected": "ප්‍රතික්ෂේප",
      "read_none": "කියවීමට යෝජනා නොමැත.",
    };

    const ta = {
      "title": "சலுகைகளை நிர்வகிக்க",
      "login_first": "முதலில் உள்நுழையவும்.",
      "pending": "நிலுவை",
      "accepted": "ஏற்றுக்கொண்டது",
      "rejected": "நிராகரிக்கப்பட்டது",
      "all": "அனைத்து",
      "filters": "டாப் உதவி",
      "no_offers": "சலுகைகள் இல்லை.",
      "tap_open": "சாட் திறக்க தொடவும்",
      "buyer": "வாங்குபவர்",
      "help": "உதவி",
      "stop": "நிறுத்து",
      "read": "படிக்க",
      "filters_help":
          "டாப்கள்: நிலுவை, ஏற்றுக்கொண்டது, நிராகரிக்கப்பட்டது, அல்லது அனைத்து. ஒரு கார்டை தொட்ந்து சாட் திறக்கலாம்.",
      "status_pending": "நிலுவை",
      "status_accepted": "ஏற்றுக்கொண்டது",
      "status_rejected": "நிராகரிக்கப்பட்டது",
      "read_none": "படிக்க சலுகைகள் இல்லை.",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  String _ttsLangCode(AppLang lang) {
    if (lang == AppLang.si) return "si-LK";
    if (lang == AppLang.ta) return "ta-IN";
    return "en-US";
  }

  String _statusLabel(AppLang lang, String status) {
    if (status == "accepted") return _t(lang, "status_accepted");
    if (status == "rejected") return _t(lang, "status_rejected");
    return _t(lang, "status_pending");
  }

  Future<void> _speakOffersGuide(AppLang lang) async {
    final langCode = _ttsLangCode(lang);

    String text;
    if (lang == AppLang.si) {
      text =
          "මෙය යෝජනා කළමනාකරණ තිරයයි. ඉහළ ටැබ් වලින් පැවතුණු, පිළිගත්, ප්‍රතික්ෂේප, හෝ සියල්ල තෝරන්න. "
          "කාඩ් එකක් ඔබා යෝජනා චැට් එක විවෘත කරන්න. Read බොත්තමෙන් පෙන්වෙන යෝජනා අහන්න. Stop බොත්තමෙන් කථනය නවතන්න.";
    } else if (lang == AppLang.ta) {
      text =
          "இது சலுகைகள் நிர்வகிக்கும் திரை. மேலே உள்ள டாப்களில் நிலுவை, ஏற்றுக்கொண்டது, நிராகரிக்கப்பட்டது அல்லது அனைத்து தேர்வு செய்யவும். "
          "ஒரு கார்டை தொட்ந்து சலுகை சாட் திறக்கவும். Read மூலம் காணப்படும் சலுகைகளை கேட்கலாம். Stop மூலம் பேசுவதை நிறுத்தலாம்.";
    } else {
      text =
          "This is the Manage Offers screen. Use the tabs to view Pending, Accepted, Rejected, or All. "
          "Tap any offer card to open the chat. Use Read to hear the visible offers. Use Stop to cancel speaking.";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  Future<void> _speakTabsHelp(AppLang lang) async {
    final langCode = _ttsLangCode(lang);

    String text;
    if (lang == AppLang.si) {
      text =
          "ටැබ් අර්ථය: පැවතුණු කියන්නේ තීරණයක් නොවූ යෝජනා. පිළිගත් කියන්නේ සම්මත කළ යෝජනා. ප්‍රතික්ෂේප කියන්නේ අහෝසි කළ යෝජනා. සියල්ල කියන්නේ සියලු යෝජනා.";
    } else if (lang == AppLang.ta) {
      text =
          "டாப்கள்: நிலுவை என்பது முடிவு செய்யாத சலுகைகள். ஏற்றுக்கொண்டது என்பது ஒப்புக்கொண்ட சலுகைகள். நிராகரிக்கப்பட்டது என்பது மறுக்கப்பட்ட சலுகைகள். அனைத்து என்பது எல்லா சலுகைகளும்.";
    } else {
      text =
          "Tabs: Pending means not decided yet. Accepted means approved offers. Rejected means declined offers. All shows every offer.";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  Future<void> _maybeSpeakNoOffers(AppLang lang) async {
    final sig = tab;
    if (_noOffersSpoken && _noOffersSig == sig) return;

    _noOffersSpoken = true;
    _noOffersSig = sig;

    final langCode = _ttsLangCode(lang);

    String text;
    if (lang == AppLang.si) {
      text = "මෙම ටැබ් සඳහා යෝජනා නොමැත.";
    } else if (lang == AppLang.ta) {
      text = "இந்த டாபில் சலுகைகள் இல்லை.";
    } else {
      text = "No offers found for this tab.";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  Future<void> _readVisibleOffers(AppLang lang) async {
    final langCode = _ttsLangCode(lang);
    await VoiceAssistant.instance.init(languageCode: langCode);

    if (_currentOffers.isEmpty) {
      await VoiceAssistant.instance.speak(_t(lang, "read_none"));
      return;
    }

    final items = _currentOffers.take(5).toList();

    String text;
    if (lang == AppLang.si) {
      text = "පෙන්වෙන යෝජනා: ";
      for (final o in items) {
        text +=
            "${o.productTitle}. තත්ත්වය ${_statusLabel(lang, o.status)}. ${o.lastMessage.isEmpty ? "" : "අවසන් පණිවිඩය: ${o.lastMessage}. "} ";
      }
    } else if (lang == AppLang.ta) {
      text = "காணப்படும் சலுகைகள்: ";
      for (final o in items) {
        text +=
            "${o.productTitle}. நிலை ${_statusLabel(lang, o.status)}. ${o.lastMessage.isEmpty ? "" : "கடைசி செய்தி: ${o.lastMessage}. "} ";
      }
    } else {
      text = "Visible offers: ";
      for (final o in items) {
        text +=
            "${o.productTitle}. Status ${_statusLabel(lang, o.status)}. ${o.lastMessage.isEmpty ? "" : "Last message: ${o.lastMessage}. "} ";
      }
    }

    await VoiceAssistant.instance.speak(text);
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

        // ✅ SELLER ONLY QUERY (no arrayContains => safer + faster)
        Query<Map<String, dynamic>> q = FirebaseFirestore.instance
            .collection("negotiations")
            .where("sellerId", isEqualTo: uid)
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
                        _circleBtn(
                          icon: Icons.stop,
                          onTap: () => VoiceAssistant.instance.stop(),
                        ),
                        const SizedBox(width: 8),
                        _circleBtn(
                          icon: Icons.record_voice_over,
                          onTap: () => _readVisibleOffers(lang),
                        ),
                        const SizedBox(width: 8),
                        _circleBtn(
                          icon: Icons.volume_up,
                          onTap: () => _speakOffersGuide(lang),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _tabs(lang),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _speakTabsHelp(lang),
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: Text(_t(lang, "filters")),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

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
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _maybeSpeakNoOffers(lang);
                          });
                          _currentOffers = const [];
                          return Center(child: Text(_t(lang, "no_offers")));
                        }

                        _currentOffers = docs
                            .map((doc) {
                              final d = doc.data();
                              return _OfferRow(
                                id: doc.id,
                                productTitle: (d["productTitle"] ?? "Product")
                                    .toString(),
                                lastMessage: (d["lastMessage"] ?? "")
                                    .toString(),
                                status: (d["status"] ?? "pending").toString(),
                                sellerId: (d["sellerId"] ?? "").toString(),
                                buyerId: (d["buyerId"] ?? "").toString(),
                              );
                            })
                            .toList(growable: false);

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final doc = docs[i];
                            final d = doc.data();

                            final productTitle =
                                (d["productTitle"] ?? "Product").toString();
                            final lastMessage = (d["lastMessage"] ?? "")
                                .toString();
                            final status = (d["status"] ?? "pending")
                                .toString();

                            final sellerId = (d["sellerId"] ?? "").toString();
                            final buyerId = (d["buyerId"] ?? "").toString();

                            // since this screen is seller-only, amSeller should be true
                            final amSeller = sellerId == uid;

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
                                      otherUserId: buyerId,
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
                                      color: Colors.black.withOpacity(0.06),
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
                                      child: const Icon(
                                        Icons.local_offer,
                                        color: Color(0xFF2A7BF4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            productTitle,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            lastMessage.isEmpty
                                                ? _t(lang, "tap_open")
                                                : lastMessage,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              _pill(
                                                _t(lang, "buyer"),
                                                const Color(0xFFF3F4F6),
                                                Colors.black87,
                                              ),
                                              const SizedBox(width: 8),
                                              _statusPill(status, lang),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.black45,
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
          color: Colors.white.withOpacity(0.22),
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
        Expanded(child: _tabBtn(_t(lang, "all"), "all")),
      ],
    );
  }

  Widget _tabBtn(String label, String value) {
    final active = tab == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() => tab = value);
        _noOffersSpoken = false;
      },
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 11),
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
        Colors.red,
      );
    }
    return _pill(
      _t(lang, "status_pending"),
      const Color(0xFFFFF7D6),
      const Color(0xFFB45309),
    );
  }
}

class _OfferRow {
  final String id;
  final String productTitle;
  final String lastMessage;
  final String status;
  final String sellerId;
  final String buyerId;

  const _OfferRow({
    required this.id,
    required this.productTitle,
    required this.lastMessage,
    required this.status,
    required this.sellerId,
    required this.buyerId,
  });
}

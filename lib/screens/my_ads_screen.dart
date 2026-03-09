import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../app_language.dart';
import '../services/voice_assistant.dart';
import 'edit_product_screen.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  String tab = "active"; // active / sold / all
  static const String _cacheBox = "myads_cache";

  // ✅ Voice
  bool _autoSpoken = false;
  bool _noAdsSpoken = false;
  String _noAdsSig = "";
  List<Map<String, dynamic>> _currentAds = const []; // for "Read" button

  @override
  void initState() {
    super.initState();

    // ✅ Auto speak once after UI loads
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

  // =========================
  // ✅ Query
  // =========================
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

  // =========================
  // ✅ Translations (EN / SI / TA)
  // =========================
  String _t(AppLang lang, String key) {
    const en = {
      "title": "My Ads",
      "login_first": "Please login first.",
      "active": "Active",
      "sold": "Sold",
      "all": "All",
      "no_ads": "No ads found.",
      "offline_cache": "Offline mode: showing cached ads",
      "help": "Help",
      "stop": "Stop",
      "read": "Read",
      "help_text":
          "This is My Ads screen. Use tabs to view Active, Sold, or All. Open menu on an ad to Edit, Mark Sold, or Delete. Use Read to hear visible ads.",
      "read_none": "There are no ads to read.",
      "status_active": "ACTIVE",
      "status_sold": "SOLD",
      "mark_sold": "Marked as sold ✅",
      "delete_ok": "Ad deleted ✅",
      "delete_failed": "Delete failed:",
      "update_failed": "Update failed:",
      "load_offline_no_cache": "Offline (no cache yet).",
      "delete_title": "Delete Ad?",
      "delete_body": "This cannot be undone.",
      "cancel": "Cancel",
      "delete": "Delete",
      "edit": "Edit",
      "menu_mark_sold": "Mark Sold",
    };

    const si = {
      "title": "මගේ දැන්වීම්",
      "login_first": "කරුණාකර පළමුව ලොගින් වන්න.",
      "active": "සක්‍රීය",
      "sold": "විකුණූ",
      "all": "සියල්ල",
      "no_ads": "දැන්වීම් නොමැත.",
      "offline_cache": "ඕෆ්ලයින්: සුරකිණි දැන්වීම් පෙන්වයි",
      "help": "උදව්",
      "stop": "නවතන්න",
      "read": "කියවන්න",
      "help_text":
          "මෙය මගේ දැන්වීම් තිරයයි. ටැබ් වලින් සක්‍රීය, විකුණූ, හෝ සියල්ල බලන්න. දැන්වීමක මෙනුවෙන් සංස්කරණය, විකුණූ ලෙස සලකුණු කිරීම, හෝ මකා දැමීම කරන්න. කියවන්න බොත්තමෙන් පෙනෙන දැන්වීම් අහන්න.",
      "read_none": "කියවීමට දැන්වීම් නැහැ.",
      "status_active": "සක්‍රීයයි",
      "status_sold": "විකුණූ",
      "mark_sold": "විකුණූ ලෙස සලකුණු විය ✅",
      "delete_ok": "දැන්වීම මකා දමන ලදි ✅",
      "delete_failed": "මකා දැමීම අසාර්ථකයි:",
      "update_failed": "යාවත්කාලීන කිරීම අසාර්ථකයි:",
      "load_offline_no_cache": "ඕෆ්ලයින් (කෑෂ් නැහැ).",
      "delete_title": "දැන්වීම මකන්නද?",
      "delete_body": "මෙය ආපසු ගත නොහැක.",
      "cancel": "අවලංගු",
      "delete": "මකන්න",
      "edit": "සංස්කරණය",
      "menu_mark_sold": "විකුණූ ලෙස සලකුණු කරන්න",
    };

    const ta = {
      "title": "என் விளம்பரங்கள்",
      "login_first": "முதலில் உள்நுழையவும்.",
      "active": "செயலில்",
      "sold": "விற்றது",
      "all": "அனைத்து",
      "no_ads": "விளம்பரங்கள் இல்லை.",
      "offline_cache": "ஆஃப்லைன்: சேமித்த விளம்பரங்கள் காட்டப்படுகிறது",
      "help": "உதவி",
      "stop": "நிறுத்து",
      "read": "படிக்க",
      "help_text":
          "இது என் விளம்பரங்கள் திரை. டாப்கள் மூலம் செயலில், விற்றது, அல்லது அனைத்து பார்க்கலாம். ஒரு விளம்பரத்தின் மெனுவில் திருத்த, விற்றது என குறி, அல்லது நீக்கு. படிக்க பொத்தான் மூலம் காணப்படும் விளம்பரங்களை கேட்கலாம்.",
      "read_none": "படிக்க விளம்பரங்கள் இல்லை.",
      "status_active": "செயலில்",
      "status_sold": "விற்றது",
      "mark_sold": "விற்றது என குறிக்கப்பட்டது ✅",
      "delete_ok": "விளம்பரம் நீக்கப்பட்டது ✅",
      "delete_failed": "நீக்க முடியவில்லை:",
      "update_failed": "புதுப்பிப்பு தோல்வி:",
      "load_offline_no_cache": "ஆஃப்லைன் (கேச் இல்லை).",
      "delete_title": "விளம்பரத்தை நீக்கவா?",
      "delete_body": "இதனை மீட்டெடுக்க முடியாது.",
      "cancel": "ரத்து",
      "delete": "நீக்கு",
      "edit": "திருத்த",
      "menu_mark_sold": "விற்றது என குறி",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  String _ttsLangCode(AppLang lang) {
    if (lang == AppLang.si) return "si-LK";
    if (lang == AppLang.ta) return "ta-IN";
    return "en-US";
  }

  // =========================
  // ✅ Voice actions
  // =========================
  Future<void> _speakHelp(AppLang lang) async {
    await VoiceAssistant.instance.init(languageCode: _ttsLangCode(lang));
    await VoiceAssistant.instance.speak(_t(lang, "help_text"));
  }

  Future<void> _readVisibleAds(AppLang lang) async {
    await VoiceAssistant.instance.init(languageCode: _ttsLangCode(lang));

    if (_currentAds.isEmpty) {
      await VoiceAssistant.instance.speak(_t(lang, "read_none"));
      return;
    }

    final items = _currentAds.take(5).toList();

    String text;
    if (lang == AppLang.si) {
      text = "පෙන්වෙන දැන්වීම්: ";
      for (final a in items) {
        final title = (a["title"] ?? "භාණ්ඩය").toString();
        final price = (a["priceRs"] as num?)?.toInt() ?? 0;
        final st = (a["status"] ?? "active").toString();
        final stLabel = (st == "sold")
            ? _t(lang, "status_sold")
            : _t(lang, "status_active");
        text += "$title. මිල රුපියල් $price. තත්ත්වය $stLabel. ";
      }
    } else if (lang == AppLang.ta) {
      text = "காணப்படும் விளம்பரங்கள்: ";
      for (final a in items) {
        final title = (a["title"] ?? "பொருள்").toString();
        final price = (a["priceRs"] as num?)?.toInt() ?? 0;
        final st = (a["status"] ?? "active").toString();
        final stLabel = (st == "sold")
            ? _t(lang, "status_sold")
            : _t(lang, "status_active");
        text += "$title. விலை ரூபாய் $price. நிலை $stLabel. ";
      }
    } else {
      text = "Visible ads: ";
      for (final a in items) {
        final title = (a["title"] ?? "Product").toString();
        final price = (a["priceRs"] as num?)?.toInt() ?? 0;
        final st = (a["status"] ?? "active").toString();
        final stLabel = (st == "sold")
            ? _t(lang, "status_sold")
            : _t(lang, "status_active");
        text += "$title. Price rupees $price. Status $stLabel. ";
      }
    }

    await VoiceAssistant.instance.speak(text);
  }

  Future<void> _maybeSpeakNoAds(AppLang lang) async {
    final sig = tab;
    if (_noAdsSpoken && _noAdsSig == sig) return;

    _noAdsSpoken = true;
    _noAdsSig = sig;

    await VoiceAssistant.instance.init(languageCode: _ttsLangCode(lang));

    String text;
    if (lang == AppLang.si) {
      text = "මෙම ටැබ් සඳහා දැන්වීම් නොමැත.";
    } else if (lang == AppLang.ta) {
      text = "இந்த டாபில் விளம்பரங்கள் இல்லை.";
    } else {
      text = "No ads found for this tab.";
    }

    await VoiceAssistant.instance.speak(text);
  }

  // =========================
  // ✅ Actions
  // =========================
  Future<void> _deleteAd(
    BuildContext context,
    AppLang lang,
    String productId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection("products")
          .doc(productId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "delete_ok"))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${_t(lang, "delete_failed")} $e")),
      );
    }
  }

  Future<void> _markSold(
    BuildContext context,
    AppLang lang,
    String productId,
  ) async {
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
      ).showSnackBar(SnackBar(content: Text(_t(lang, "mark_sold"))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${_t(lang, "update_failed")} $e")),
      );
    }
  }

  String _fmtPrice(dynamic v) {
    final n = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
    return "Rs $n";
  }

  // =========================
  // ✅ Offline cache (Hive)
  // =========================
  Future<void> _saveCache(
    String uid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final box = Hive.box(_cacheBox);
    final key = "${uid}_$tab";

    final list = docs.map((d) {
      final data = d.data();
      return {"id": d.id, ...data};
    }).toList();

    await box.put(key, list);
    await box.put("${key}_time", DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>> _loadCache(String uid) {
    final box = Hive.box(_cacheBox);
    final key = "${uid}_$tab";

    final raw = box.get(key);
    if (raw is! List) return [];

    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // =========================
  // ✅ UI
  // =========================
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

                        // ✅ Voice buttons
                        _circleBtn(
                          icon: Icons.stop,
                          onTap: () => VoiceAssistant.instance.stop(),
                        ),
                        const SizedBox(width: 8),
                        _circleBtn(
                          icon: Icons.record_voice_over,
                          onTap: () => _readVisibleAds(lang),
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
                    child: Row(
                      children: [
                        Expanded(child: _tabBtn(_t(lang, "active"), "active")),
                        const SizedBox(width: 8),
                        Expanded(child: _tabBtn(_t(lang, "sold"), "sold")),
                        const SizedBox(width: 8),
                        Expanded(child: _tabBtn(_t(lang, "all"), "all")),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: q.snapshots(),
                      builder: (context, snap) {
                        // ✅ ONLINE data available
                        if (snap.hasData) {
                          final docs = snap.data?.docs ?? [];
                          _saveCache(uid, docs); // save (no await)

                          // keep visible list for voice "Read"
                          _currentAds = docs
                              .map((d) => d.data())
                              .toList(growable: false);

                          if (docs.isEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _maybeSpeakNoAds(lang);
                            });
                            return Center(child: Text(_t(lang, "no_ads")));
                          }

                          return _buildListFromDocs(lang, docs);
                        }

                        // ✅ OFFLINE / ERROR fallback
                        final cached = _loadCache(uid);
                        _currentAds = cached; // for voice "Read"

                        if (cached.isEmpty) {
                          if (snap.hasError) {
                            return Center(
                              child: Text(
                                "${_t(lang, "load_offline_no_cache")}\n${snap.error}",
                              ),
                            );
                          }
                          return Center(
                            child: Text(_t(lang, "load_offline_no_cache")),
                          );
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted)
                            _maybeSpeakNoAds(
                              lang,
                            ); // only if no ads in current tab (cache exists though)
                        });

                        return Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7D6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.wifi_off,
                                    color: Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _t(lang, "offline_cache"),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: _buildListFromCache(lang, cached)),
                          ],
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

  Widget _buildListFromDocs(
    AppLang lang,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final doc = docs[i];
        final d = doc.data();
        return _adTile(lang: lang, productId: doc.id, d: d, isCached: false);
      },
    );
  }

  Widget _buildListFromCache(AppLang lang, List<Map<String, dynamic>> cached) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: cached.length,
      itemBuilder: (_, i) {
        final m = cached[i];
        final id = (m["id"] ?? "").toString();
        final d = Map<String, dynamic>.from(m)..remove("id");
        return _adTile(lang: lang, productId: id, d: d, isCached: true);
      },
    );
  }

  Widget _adTile({
    required AppLang lang,
    required String productId,
    required Map<String, dynamic> d,
    required bool isCached,
  }) {
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
                    child: const Icon(Icons.image_not_supported_outlined),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFE5E7EB),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFE5E7EB),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? "Untitled" : title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
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
                _statusPill(lang, status),
              ],
            ),
          ),
          const SizedBox(width: 10),

          PopupMenuButton<String>(
            enabled: !isCached, // ✅ disable actions in offline cache view
            onSelected: (v) async {
              if (v == "edit") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProductScreen(productId: productId),
                  ),
                );
              }
              if (v == "sold") {
                await _markSold(context, lang, productId);
              }
              if (v == "delete") {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(_t(lang, "delete_title")),
                    content: Text(_t(lang, "delete_body")),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(_t(lang, "cancel")),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(_t(lang, "delete")),
                      ),
                    ],
                  ),
                );
                if (ok == true) await _deleteAd(context, lang, productId);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: "edit", child: Text(_t(lang, "edit"))),
              if (status == "active")
                PopupMenuItem(
                  value: "sold",
                  child: Text(_t(lang, "menu_mark_sold")),
                ),
              PopupMenuItem(value: "delete", child: Text(_t(lang, "delete"))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, String value) {
    final active = tab == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() => tab = value);
        _noAdsSpoken = false; // allow no-ads voice again for new tab
      },
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

  Widget _statusPill(AppLang lang, String status) {
    if (status == "sold") {
      return _pill(
        _t(lang, "status_sold"),
        const Color(0xFFE5E7EB),
        Colors.black54,
      );
    }
    return _pill(
      _t(lang, "status_active"),
      const Color(0xFFD9FFE6),
      const Color(0xFF16A34A),
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
}

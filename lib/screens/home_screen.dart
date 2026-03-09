import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_language.dart';

// ✅ AI tips (your files)
import '../services/ai_tips_service.dart';
import '../widgets/ai_tips_card.dart';

// ✅ Voice help service
import '../services/voice_assistant.dart';

import 'profile_screen.dart';
import 'splash_screen.dart';
import 'buy_products_screen.dart';
import 'manage_offers_screen.dart';
import 'my_offers_screen.dart'; // ✅ ADDED
import 'add_product_screen.dart';
import 'seller_orders_screen.dart';
import 'my_purchases_screen.dart';
import 'my_ads_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum SyncUiState { idle, syncing, error }

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  // ✅ Offline indicator (Connectivity Plus v6+ returns List<ConnectivityResult>)
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  // ✅ Sync status chip
  final ValueNotifier<SyncUiState> _syncState = ValueNotifier(SyncUiState.idle);

  // ✅ Tip of the day
  String _tipText = "Loading tip...";

  // ✅ Auto speak once (Home tab only)
  bool _autoSpokenHome = false;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadTip();

    // ✅ Auto speak once after UI loads (Home tab only)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_tab != 0) return;
      if (_autoSpokenHome) return;

      _autoSpokenHome = true;
      final lang = AppLanguage.current.value;
      await _speakHomeGuide(lang);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _syncState.dispose();
    VoiceAssistant.instance.stop();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    final conn = Connectivity();

    final results = await conn.checkConnectivity();
    _applyConnectivity(results);

    _connSub = conn.onConnectivityChanged.listen(_applyConnectivity);
  }

  void _applyConnectivity(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!mounted) return;
    setState(() => _isOffline = !online);
  }

  Future<void> _loadTip() async {
    final tip = await AiTipsService.getTodayTip();
    if (!mounted) return;
    setState(() => _tipText = tip);
  }

  // ✅ connect to your real sync later
  Future<void> _syncNow(AppLang lang) async {
    if (_isOffline) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "sync_offline"))));
      return;
    }

    if (_syncState.value == SyncUiState.syncing) return;

    _syncState.value = SyncUiState.syncing;
    try {
      await Future.delayed(const Duration(seconds: 1));
      _syncState.value = SyncUiState.idle;

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "synced"))));
    } catch (_) {
      _syncState.value = SyncUiState.error;

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "sync_failed"))));
    }
  }

  // =========================
  // ✅ Voice guide (English/Sinhala/Tamil)
  // =========================
  String _ttsLangCode(AppLang lang) {
    if (lang == AppLang.si) return "si-LK";
    if (lang == AppLang.ta) return "ta-IN";
    return "en-US";
  }

  Future<void> _speakHomeGuide(AppLang lang) async {
    final langCode = _ttsLangCode(lang);

    String text;
    if (lang == AppLang.si) {
      text =
          "මෙය මුල් පිටුවයි. භාණ්ඩ විකුණන්න සඳහා ‘භාණ්ඩ විකුණන්න’ ඔබන්න. "
          "භාණ්ඩ මිලදී ගැනීමට ‘භාණ්ඩ මිලදී ගන්න’ ඔබන්න. "
          "‘මගේ යෝජනා’ මඟින් ඔබ යවපු යෝජනා බලන්න. "
          "‘යෝජනා කළමනාකරණය’ මඟින් ලැබුණු යෝජනා කළමනාකරණය කරන්න. "
          "ඇණවුම් බලන්න ‘මගේ ඇණවුම්’ සහ ඔබ මිලදීගත් දේ ‘මගේ මිලදී ගැනීම්’ මඟින් බලන්න. "
          "AI උපදෙස් කාඩ් එකෙන් අද උපදෙස බලන්න. Stop මඟින් කථනය නවතන්න. Read මඟින් සාරාංශය අහන්න.";
    } else if (lang == AppLang.ta) {
      text =
          "இது முகப்பு திரை. பொருள் விற்க ‘விற்கவும்’ அழுத்தவும். "
          "பொருட்களை பார்க்க ‘வாங்கவும்’ அழுத்தவும். "
          "‘என் சலுகைகள்’ மூலம் நீங்கள் அனுப்பிய சலுகைகளை பார்க்கலாம். "
          "‘சலுகைகள் நிர்வகிக்க’ மூலம் வந்த சலுகைகளை நிர்வகிக்கலாம். "
          "‘என் ஆர்டர்கள்’ மற்றும் ‘என் வாங்கியவை’ மூலம் நிலையை பார்க்கலாம். "
          "AI குறிப்பு கார்டில் இன்று குறிப்பு இருக்கும். Stop மூலம் பேசுவதை நிறுத்தலாம். Read மூலம் சுருக்கம் கேட்கலாம்.";
    } else {
      text =
          "This is the Home screen. Tap Sell to post a product. Tap Buy to browse products. "
          "Use My Offers to check offers you sent. Use Manage Offers to control incoming offers. "
          "Use My Orders and My Purchases to track status. Check the AI Tip card for today. "
          "Use Stop to cancel speaking. Use Read to hear a short summary.";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  Future<void> _speakHomeSummary(AppLang lang) async {
    final langCode = _ttsLangCode(lang);

    String text;
    if (lang == AppLang.si) {
      text =
          "සාරාංශය. විකුණන්න, මිලදී ගන්න, මගේ ඇණවුම්, මගේ මිලදී ගැනීම්, මගේ දැන්වීම්, මගේ යෝජනා, යෝජනා කළමනාකරණය. "
          "අද AI උපදෙස: $_tipText";
    } else if (lang == AppLang.ta) {
      text =
          "சுருக்கம். விற்கவும், வாங்கவும், என் ஆர்டர்கள், என் வாங்கியவை, என் விளம்பரங்கள், என் சலுகைகள், சலுகைகள் நிர்வகிக்க. "
          "இன்றைய AI குறிப்பு: $_tipText";
    } else {
      text =
          "Summary. Sell, Buy, My Orders, My Purchases, My Ads, My Offers, Manage Offers. "
          "Today’s AI tip: $_tipText";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  // =========================
  // ✅ Translations
  // =========================
  String _t(AppLang lang, String key) {
    const en = {
      "welcome": "Welcome back!",
      "ready": "Ready to trade today?",
      "sell": "Sell Product",
      "buy": "Buy Products",
      "nearby": "Nearby Traders",
      "my_orders": "My Orders",
      "my_purchases": "My Purchases",
      "my_ads": "My Ads",
      "my_offers": "My Offers", // ✅ ADDED
      "summary": "Today’s Summary",
      "products": "Products",
      "sold": "Sold",
      "offers": "Offers",
      "manage_offers": "Manage Offers",
      "ai_tip_title": "AI Tip of the Day",
      "logout": "Logout",
      "home": "Home",
      "sell_nav": "Sell",
      "profile": "Profile",
      "offline_title": "You're Offline",
      "offline_desc": "Changes will sync automatically when connected.",
      "sync_now": "Sync Now",
      "sync_offline":
          "You're offline. Sync will run automatically when online.",
      "synced": "Synced ✅",
      "sync_failed": "Sync failed ❌",
      "help": "Help",
      "stop": "Stop",
      "read": "Read",
    };

    const si = {
      "welcome": "ආයුබෝවන්!",
      "ready": "අද ගනුදෙනු කිරීමට සූදානම් ද?",
      "sell": "භාණ්ඩ විකුණන්න",
      "buy": "භාණ්ඩ මිලදී ගන්න",
      "nearby": "ළඟම වෙළෙන්දෝ",
      "my_orders": "මගේ ඇණවුම්",
      "my_purchases": "මගේ මිලදී ගැනීම්",
      "my_ads": "මගේ දැන්වීම්",
      "my_offers": "මගේ යෝජනා", // ✅ ADDED
      "summary": "අද සාරාංශය",
      "products": "භාණ්ඩ",
      "sold": "විකුණූ",
      "offers": "යෝජනා",
      "manage_offers": "යෝජනා කළමනාකරණය",
      "ai_tip_title": "අද AI උපදෙස්",
      "logout": "ඉවත් වන්න",
      "home": "මුල් පිටුව",
      "sell_nav": "විකුණන්න",
      "profile": "පැතිකඩ",
      "offline_title": "ඔබ Offline",
      "offline_desc": "සම්බන්ධ වූ විට ස්වයංක්‍රීයව Sync වේ.",
      "sync_now": "දැන් Sync",
      "sync_offline": "ඔබ Offline. Online වූ විට Sync වේ.",
      "synced": "Sync විය ✅",
      "sync_failed": "Sync අසාර්ථකයි ❌",
      "help": "උදව්",
      "stop": "නවතන්න",
      "read": "කියවන්න",
    };

    const ta = {
      "welcome": "மீண்டும் வரவேற்கிறோம்!",
      "ready": "இன்று வர்த்தகம் செய்ய தயாரா?",
      "sell": "விற்கவும்",
      "buy": "வாங்கவும்",
      "nearby": "அருகிலுள்ள வியாபாரிகள்",
      "my_orders": "என் ஆர்டர்கள்",
      "my_purchases": "என் வாங்கியவை",
      "my_ads": "என் விளம்பரங்கள்",
      "my_offers": "என் சலுகைகள்", // ✅ ADDED
      "summary": "இன்றைய சுருக்கம்",
      "products": "பொருட்கள்",
      "sold": "விற்றது",
      "offers": "சலுகைகள்",
      "manage_offers": "சலுகைகள் நிர்வகிக்க",
      "ai_tip_title": "இன்றைய AI குறிப்பு",
      "logout": "வெளியேறு",
      "home": "முகப்பு",
      "sell_nav": "விற்க",
      "profile": "சுயவிவரம்",
      "offline_title": "நீங்கள் Offline",
      "offline_desc": "இணைந்ததும் தானாக Sync ஆகும்.",
      "sync_now": "இப்போது Sync",
      "sync_offline": "நீங்கள் Offline. Online ஆனதும் Sync ஆகும்.",
      "synced": "Sync ஆனது ✅",
      "sync_failed": "Sync தோல்வி ❌",
      "help": "உதவி",
      "stop": "நிறுத்து",
      "read": "படிக்க",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
        final body = (_tab == 0)
            ? _homeBody(context, lang)
            : (_tab == 1)
            ? const AddProductScreen()
            : const ProfileScreen();

        return Scaffold(
          body: body,

          // ✅ Home tab: Stop + Read + Help (stacked FABs)
          floatingActionButton: (_tab == 0)
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: "home_stop",
                      onPressed: () => VoiceAssistant.instance.stop(),
                      backgroundColor: Colors.black87,
                      child: const Icon(Icons.stop, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.extended(
                      heroTag: "home_read",
                      onPressed: () => _speakHomeSummary(lang),
                      backgroundColor: const Color(0xFF7C3AED),
                      icon: const Icon(
                        Icons.record_voice_over,
                        color: Colors.white,
                      ),
                      label: Text(
                        _t(lang, "read"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.extended(
                      heroTag: "home_help",
                      onPressed: () => _speakHomeGuide(lang),
                      backgroundColor: const Color(0xFF2A7BF4),
                      icon: const Icon(Icons.volume_up, color: Colors.white),
                      label: Text(
                        _t(lang, "help"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) {
              setState(() => _tab = i);
            },
            selectedItemColor: const Color(0xFF2BB673),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                label: _t(lang, "home"),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.add_circle_outline),
                label: _t(lang, "sell_nav"),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                label: _t(lang, "profile"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _homeBody(BuildContext context, AppLang lang) {
    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.phoneNumber ?? "+94 XX XXX XXXX";

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4FFFA), Color(0xFFEFF7FF)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isOffline) _offlineBanner(lang),

              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2BB673), Color(0xFF2A7BF4)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Trade Connect",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Connect. Trade. Grow.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<SyncUiState>(
                      valueListenable: _syncState,
                      builder: (_, st, __) => _syncChip(st, lang),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => setState(() => _tab = 2),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Welcome card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text("👋", style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t(lang, "welcome"),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "${_t(lang, "ready")} • $phone",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Row 1
              Row(
                children: [
                  Expanded(
                    child: _featureCard(
                      title: _t(lang, "sell"),
                      emoji: "🧺",
                      gradient: const [Color(0xFF22C55E), Color(0xFF16A34A)],
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _featureCard(
                      title: _t(lang, "buy"),
                      emoji: "🛒",
                      gradient: const [Color(0xFF2563EB), Color(0xFF60A5FA)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BuyProductsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Row 2
              Row(
                children: [
                  Expanded(
                    child: _featureCard(
                      title: _t(lang, "my_offers"), // ✅ CHANGED
                      emoji: "💬",
                      gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyOffersScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _featureCard(
                      title: _t(lang, "my_orders"),
                      emoji: "📦",
                      gradient: const [Color(0xFFF97316), Color(0xFFFB7185)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SellerOrdersScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Row 3
              Row(
                children: [
                  Expanded(
                    child: _featureCard(
                      title: _t(lang, "my_purchases"),
                      emoji: "🧾",
                      gradient: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyPurchasesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _featureCard(
                      title: _t(lang, "my_ads"),
                      emoji: "📣",
                      gradient: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyAdsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Summary + Manage Offers
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(lang, "summary"),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MiniStat(
                          value: "12",
                          label: _t(lang, "products"),
                          icon: Icons.bar_chart,
                          valueColor: const Color(0xFF16A34A),
                        ),
                        _MiniStat(
                          value: "5",
                          label: _t(lang, "offers"),
                          icon: Icons.chat_bubble_outline,
                          valueColor: const Color(0xFF2563EB),
                        ),
                        _MiniStat(
                          value: "3",
                          label: _t(lang, "sold"),
                          icon: Icons.check_circle_outline,
                          valueColor: const Color(0xFFF97316),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageOffersScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.work_outline,
                          color: Colors.white,
                        ),
                        label: Text(
                          _t(lang, "manage_offers"),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ✅ AI Tip card
              AiTipCard(
                title: _t(lang, "ai_tip_title"),
                tip: _tipText,
                onNext: () async {
                  final tip = await AiTipsService.nextTip();
                  if (!mounted) return;
                  setState(() => _tipText = tip);
                },
              ),

              const SizedBox(height: 16),

              // Logout
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(_t(lang, "logout")),
                ),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _offlineBanner(AppLang lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "${_t(lang, "offline_title")}\n${_t(lang, "offline_desc")}",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => _syncNow(lang),
            child: Text(_t(lang, "sync_now")),
          ),
        ],
      ),
    );
  }

  Widget _syncChip(SyncUiState st, AppLang lang) {
    String text = "Idle";
    IconData icon = Icons.cloud_done;

    if (st == SyncUiState.syncing) {
      text = "Sync";
      icon = Icons.sync;
    } else if (st == SyncUiState.error) {
      text = "Err";
      icon = Icons.error_outline;
    }

    return InkWell(
      onTap: () => _syncNow(lang),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureCard({
    required String title,
    required String emoji,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(colors: gradient),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color valueColor;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

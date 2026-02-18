import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_language.dart';
import 'profile_screen.dart';
import 'splash_screen.dart';
import 'buy_products_screen.dart';
import 'manage_offers_screen.dart';
import 'add_product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  String _t(AppLang lang, String key) {
    const en = {
      "welcome": "Welcome back!",
      "ready": "Ready to trade today?",
      "sell": "Sell Product",
      "buy": "Buy Products",
      "nearby": "Nearby Traders",
      "my_orders": "My Orders",
      "summary": "Today’s Summary",
      "products": "Products",
      "orders": "Orders",
      "sold": "Sold",
      "offers": "Offers",
      "manage_offers": "Manage Offers",
      "new": "New",
      "ai_tip_title": "AI Tip of the Day",
      "ai_tip": "Try pricing your item 5–10% below market for faster sales!",
      "logout": "Logout",
      "home": "Home",
      "sell_nav": "Sell",
      "profile": "Profile",
    };

    const si = {
      "welcome": "ආයුබෝවන්!",
      "ready": "අද ගනුදෙනු කිරීමට සූදානම් ද?",
      "sell": "භාණ්ඩ විකුණන්න",
      "buy": "භාණ්ඩ මිලදී ගන්න",
      "nearby": "ළඟම වෙළෙන්දෝ",
      "my_orders": "මගේ ඇණවුම්",
      "summary": "අද සාරාංශය",
      "products": "භාණ්ඩ",
      "orders": "ඇණවුම්",
      "sold": "විකුණූ",
      "offers": "යෝජනා",
      "manage_offers": "යෝජනා කළමනාකරණය",
      "new": "නව",
      "ai_tip_title": "අද AI උපදෙස්",
      "ai_tip":
          "වේගයෙන් විකිණීමට වෙළඳපොළ වටිනාකමින් 5–10%ක් අඩුවෙන් මිල දාන්න!",
      "logout": "ඉවත් වන්න",
      "home": "මුල් පිටුව",
      "sell_nav": "විකුණන්න",
      "profile": "පැතිකඩ",
    };

    const ta = {
      "welcome": "மீண்டும் வரவேற்கிறோம்!",
      "ready": "இன்று வர்த்தகம் செய்ய தயாரா?",
      "sell": "விற்கவும்",
      "buy": "வாங்கவும்",
      "nearby": "அருகிலுள்ள வியாபாரிகள்",
      "my_orders": "என் ஆர்டர்கள்",
      "summary": "இன்றைய சுருக்கம்",
      "products": "பொருட்கள்",
      "orders": "ஆர்டர்கள்",
      "sold": "விற்றது",
      "offers": "சலுகைகள்",
      "manage_offers": "சலுகைகள் நிர்வகிக்க",
      "new": "புதிய",
      "ai_tip_title": "இன்றைய AI குறிப்பு",
      "ai_tip":
          "விரைவாக விற்க சந்தை விலையை விட 5–10% குறைவாக விலை நிர்ணயிக்கவும்!",
      "logout": "வெளியேறு",
      "home": "முகப்பு",
      "sell_nav": "விற்க",
      "profile": "சுயவிவரம்",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
        final body = switch (_tab) {
          0 => _homeBody(context, lang),
          1 => const AddProductScreen(),
          _ => const ProfileScreen(),
        };

        return Scaffold(
          body: body,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) => setState(() => _tab = i),
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

              // Feature grid
              Row(
                children: [
                  Expanded(
                    child: _featureCard(
                      title: _t(lang, "sell"),
                      emoji: "🧺",
                      gradient: const [Color(0xFF22C55E), Color(0xFF16A34A)],
                      // ✅ FIX: direct open AddProduct via tab
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
              Row(
                children: [
                  Expanded(
                    child: _featureCard(
                      title: _t(lang, "nearby"),
                      emoji: "📍",
                      gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Nearby traders (next)"),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("My orders (next)")),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Today’s Summary
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
                    Stack(
                      children: [
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
                        Positioned(
                          right: 14,
                          top: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5A5A),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              "2 ${_t(lang, "new")}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // AI Tip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFCE7F3), Color(0xFFE0F2FE)],
                  ),
                ),
                child: Row(
                  children: [
                    const Text("✨", style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${_t(lang, "ai_tip_title")}\n${_t(lang, "ai_tip")}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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
            ],
          ),
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

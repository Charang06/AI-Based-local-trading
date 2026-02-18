import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_language.dart';
import 'language_screen.dart';
import 'splash_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool offlineMode = false;

  String _langCode(AppLang lang) {
    switch (lang) {
      case AppLang.en:
        return "EN";
      case AppLang.si:
        return "SI";
      case AppLang.ta:
        return "TA";
    }
  }

  // ✅ Translations
  String _t(AppLang lang, String key) {
    const en = {
      "profile": "Profile",
      "language": "Language",
      "tutorials": "Watch Tutorials",
      "offline": "Offline Mode",
      "help": "Help & Support",
      "settings": "Settings",
      "voice_title": "Voice Instructions",
      "voice_desc": "Listen to voice guides for every screen. Tap the speaker icon anytime!",
      "voice_btn": "Enable Voice Guide",
      "logout": "Logout",
      "products": "Products",
      "sold": "Sold",
      "rating": "Rating ⭐",
      "user": "Trade Connect User",
      "settings_next": "Settings (next)",
      "tutorials_next": "Tutorials (next)",
      "help_next": "Help & Support (next)",
      "voice_enabled": "Voice Guide enabled (demo) ✅",
    };

    const si = {
      "profile": "පැතිකඩ",
      "language": "භාෂාව",
      "tutorials": "ඉගෙනුම් වීඩියෝ",
      "offline": "ඕෆ්ලයින් මාදිලිය",
      "help": "උදව් සහ සහය",
      "settings": "සැකසුම්",
      "voice_title": "හඬ උපදෙස්",
      "voice_desc": "සෑම තිරයකටම හඬ මඟපෙන්වීම් අසන්න. ඕනෑම වෙලාවක Speaker අයිකනය ඔබන්න!",
      "voice_btn": "හඬ මාර්ගෝපදේශය සක්‍රිය කරන්න",
      "logout": "ඉවත් වන්න",
      "products": "භාණ්ඩ",
      "sold": "විකුණූ",
      "rating": "ශ්‍රේණිගත ⭐",
      "user": "Trade Connect පරිශීලකයා",
      "settings_next": "සැකසුම් (ඊළඟ)",
      "tutorials_next": "ඉගෙනුම් (ඊළඟ)",
      "help_next": "උදව් (ඊළඟ)",
      "voice_enabled": "හඬ මාර්ගෝපදේශය සක්‍රියයි ✅",
    };

    const ta = {
      "profile": "சுயவிவரம்",
      "language": "மொழி",
      "tutorials": "வீடியோ வழிகாட்டிகள்",
      "offline": "ஆஃப்லைன் முறை",
      "help": "உதவி & ஆதரவு",
      "settings": "அமைப்புகள்",
      "voice_title": "குரல் வழிமுறைகள்",
      "voice_desc": "ஒவ்வொரு திரைக்கும் குரல் வழிகாட்டி. எப்போது வேண்டுமானாலும் Speaker ஐகானை தட்டுங்கள்!",
      "voice_btn": "குரல் வழிகாட்டியை இயக்கவும்",
      "logout": "வெளியேறு",
      "products": "பொருட்கள்",
      "sold": "விற்றது",
      "rating": "மதிப்பீடு ⭐",
      "user": "Trade Connect பயனர்",
      "settings_next": "அமைப்புகள் (அடுத்தது)",
      "tutorials_next": "வழிகாட்டிகள் (அடுத்தது)",
      "help_next": "உதவி (அடுத்தது)",
      "voice_enabled": "குரல் வழிகாட்டி இயக்கு ✅",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
        final name = (user?.displayName?.trim().isNotEmpty == true)
            ? user!.displayName!
            : _t(lang, "user");

        final phone = user?.phoneNumber ?? "+94 XX XXX XXXX";

        return Scaffold(
          backgroundColor: const Color(0xFFF4FFFA),
          body: Stack(
            children: [
              Container(
                height: 190,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF2A7BF4)],
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Top AppBar row
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _t(lang, "profile"),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      _userCard(
                        name: name,
                        phone: phone,
                        products: 24,
                        sold: 18,
                        rating: 4.8,
                        lang: lang,
                      ),

                      const SizedBox(height: 16),

                      _tile(
                        leadingEmoji: "🌍",
                        title: _t(lang, "language"),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _langCode(lang),
                            style: const TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LanguageScreen()),
                          );
                        },
                      ),

                      _tile(
                        leadingEmoji: "🎥",
                        title: _t(lang, "tutorials"),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_t(lang, "tutorials_next"))),
                          );
                        },
                      ),

                      _switchTile(
                        leadingEmoji: "📴",
                        title: _t(lang, "offline"),
                        value: offlineMode,
                        onChanged: (v) => setState(() => offlineMode = v),
                      ),

                      _tile(
                        leadingEmoji: "❓",
                        title: _t(lang, "help"),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_t(lang, "help_next"))),
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      _tile(
                        leadingIcon: Icons.settings,
                        title: _t(lang, "settings"),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_t(lang, "settings_next"))),
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      _voiceCard(
                        lang: lang,
                        onEnable: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_t(lang, "voice_enabled"))),
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFFFECEC),
                          ),
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
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: Text(
                              _t(lang, "logout"),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- UI widgets ----------------

  Widget _userCard({
    required String name,
    required String phone,
    required int products,
    required int sold,
    required double rating,
    required AppLang lang,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF2A7BF4)],
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(phone, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat(value: "$products", label: _t(lang, "products"), valueColor: Colors.green),
              _stat(value: "$sold", label: _t(lang, "sold"), valueColor: Colors.blue),
              _stat(value: rating.toStringAsFixed(1), label: _t(lang, "rating"), valueColor: Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _tile({
    String? leadingEmoji,
    IconData? leadingIcon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: leadingIcon != null
                ? Icon(leadingIcon, color: const Color(0xFF6B7280))
                : Text(leadingEmoji ?? "•", style: const TextStyle(fontSize: 18)),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _switchTile({
    required String leadingEmoji,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(leadingEmoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }

  Widget _voiceCard({required AppLang lang, required VoidCallback onEnable}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFD9FFE6), Color(0xFFDAE7FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic, color: Color(0xFF2BB673)),
              const SizedBox(width: 10),
              Text(
                _t(lang, "voice_title"),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _t(lang, "voice_desc"),
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: onEnable,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                _t(lang, "voice_btn"),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

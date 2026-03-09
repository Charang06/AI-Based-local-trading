import 'package:flutter/material.dart';

import '../app_language.dart';
import '../services/voice_assistant.dart';
import 'onboarding_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  bool _autoSpoken = false;

  @override
  void initState() {
    super.initState();

    // ✅ Auto speak once after UI loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _autoSpoken) return;
      _autoSpoken = true;

      final lang = AppLanguage.current.value;
      await _speakLanguageGuide(lang);
    });
  }

  @override
  void dispose() {
    VoiceAssistant.instance.stop();
    super.dispose();
  }

  String _title(AppLang lang) {
    switch (lang) {
      case AppLang.ta:
        return "மொழியைத் தேர்ந்தெடுக்கவும்";
      case AppLang.si:
        return "භාෂාව තෝරන්න";
      case AppLang.en:
        return "Select Your Language";
    }
  }

  String _subtitle(AppLang lang) {
    switch (lang) {
      case AppLang.ta:
        return "உங்கள் விருப்பமான மொழியை தேர்ந்தெடுக்கவும்";
      case AppLang.si:
        return "ඔබ කැමති භාෂාව තෝරන්න";
      case AppLang.en:
        return "Choose your preferred language";
    }
  }

  String _t(AppLang lang, String key) {
    const en = {
      "help": "Help",
      "stop": "Stop",
      "guide":
          "Select your language. Tap English, Sinhala, or Tamil to continue to onboarding.",
    };
    const si = {
      "help": "උදව්",
      "stop": "නවතන්න",
      "guide": "ඔබේ භාෂාව තෝරන්න. English, සිංහල හෝ தமிழ் මත ඔබා ඉදිරියට යන්න.",
    };
    const ta = {
      "help": "உதவி",
      "stop": "நிறுத்து",
      "guide":
          "உங்கள் மொழியை தேர்ந்தெடுக்கவும். English, සිංහල அல்லது தமிழ் தேர்வு செய்து தொடரவும்.",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  String _ttsLangCode(AppLang lang) {
    if (lang == AppLang.si) return "si-LK";
    if (lang == AppLang.ta) return "ta-IN";
    return "en-US";
  }

  Future<void> _speakLanguageGuide(AppLang lang) async {
    final langCode = _ttsLangCode(lang);
    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(_t(lang, "guide"));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, currentLang, _) {
        return Scaffold(
          // ✅ Stop + Help (same style as other screens)
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: "lang_stop",
                onPressed: () => VoiceAssistant.instance.stop(),
                backgroundColor: Colors.black87,
                child: const Icon(Icons.stop, color: Colors.white),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: "lang_help",
                onPressed: () => _speakLanguageGuide(currentLang),
                backgroundColor: const Color(0xFF2A7BF4),
                icon: const Icon(Icons.volume_up, color: Colors.white),
                label: Text(
                  _t(currentLang, "help"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF6FFFB), Color(0xFFEFF8FF)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE9F7FF),
                      ),
                      child: const Center(
                        child: Text("🌍", style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _title(currentLang),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitle(currentLang),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    languageCard(
                      context,
                      currentLang: currentLang,
                      code: "GB",
                      title: "English",
                      subtitle: "English",
                      lang: AppLang.en,
                    ),
                    const SizedBox(height: 14),
                    languageCard(
                      context,
                      currentLang: currentLang,
                      code: "LK",
                      title: "සිංහල",
                      subtitle: "Sinhala",
                      lang: AppLang.si,
                    ),
                    const SizedBox(height: 14),
                    languageCard(
                      context,
                      currentLang: currentLang,
                      code: "LK",
                      title: "தமிழ்",
                      subtitle: "Tamil",
                      lang: AppLang.ta,
                    ),
                    const SizedBox(height: 90), // space for FABs
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget languageCard(
    BuildContext context, {
    required AppLang currentLang,
    required String code,
    required String title,
    required String subtitle,
    required AppLang lang,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        // ✅ stop current voice when changing language
        VoiceAssistant.instance.stop();

        // ✅ set selected language
        AppLanguage.setLang(lang);

        // ✅ go to onboarding
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

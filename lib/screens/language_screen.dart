import 'package:flutter/material.dart';
import '../app_language.dart';
import 'onboarding_screen.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, currentLang, _) {
        return Scaffold(
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
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    languageCard(
                      context,
                      code: "GB",
                      title: "English",
                      subtitle: "English",
                      lang: AppLang.en,
                    ),
                    const SizedBox(height: 14),
                    languageCard(
                      context,
                      code: "LK",
                      title: "සිංහල",
                      subtitle: "Sinhala",
                      lang: AppLang.si,
                    ),
                    const SizedBox(height: 14),
                    languageCard(
                      context,
                      code: "LK",
                      title: "தமிழ்",
                      subtitle: "Tamil",
                      lang: AppLang.ta,
                    ),
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
    required String code,
    required String title,
    required String subtitle,
    required AppLang lang,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
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
              color: Colors.black.withOpacity(0.06),
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
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
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

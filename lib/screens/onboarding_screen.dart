import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../app_language.dart';
import 'phone_login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  AppLang? _lastLang; // ✅ track language changes

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
    );
  }

  void _next(int totalPages) {
    if (_index < totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _goLogin();
    }
  }

  List<_OnboardPage> _pagesFor(AppLang lang) {
    if (lang == AppLang.ta) {
      return const [
        _OnboardPage(
          icon: Icons.shopping_cart_outlined,
          iconColor: Colors.green,
          title: "எளிதாக வாங்கவும்\nவிற்கவும்",
          subtitle: "அருகிலுள்ள விற்பனையாளர்களுடன்\nபொருட்களை வாங்கவும், விற்கவும்",
          buttonText: "அடுத்து",
        ),
        _OnboardPage(
          icon: Icons.auto_awesome,
          iconColor: Colors.deepPurple,
          title: "AI உடன் நியாயமான\nவிலைகள்",
          subtitle: "சிறந்த விலை பரிந்துரைகள் பெறுங்கள்",
          buttonText: "அடுத்து",
        ),
        _OnboardPage(
          icon: Icons.wifi_off,
          iconColor: Colors.blue,
          title: "ஆஃப்லைனிலும்\nபயன்படுத்து",
          subtitle: "இணையம் இல்லாமலும் செயலியை பயன்படுத்தலாம்",
          buttonText: "தொடங்குங்கள்",
        ),
      ];
    }

    if (lang == AppLang.si) {
      return const [
        _OnboardPage(
          icon: Icons.shopping_cart_outlined,
          iconColor: Colors.green,
          title: "ලේසියෙන් මිලදී ගන්න\nසැණින් විකුණන්න",
          subtitle: "ළඟම විකිණුම්කරුවන් සමඟ\nභාණ්ඩ ගනුදෙනු කරන්න",
          buttonText: "ඊළඟ",
        ),
        _OnboardPage(
          icon: Icons.auto_awesome,
          iconColor: Colors.deepPurple,
          title: "AI සමඟ සාධාරණ\nමිල ගණන්",
          subtitle: "හොඳම මිල යෝජනා ලබා ගන්න",
          buttonText: "ඊළඟ",
        ),
        _OnboardPage(
          icon: Icons.wifi_off,
          iconColor: Colors.blue,
          title: "අන්තර්ජාලය නැතිවත්\nභාවිතා කරන්න",
          subtitle: "ඕෆ්ලයින්දීත් යෙදුම භාවිතා කළ හැක",
          buttonText: "ආරම්භ කරන්න",
        ),
      ];
    }

    return const [
      _OnboardPage(
        icon: Icons.shopping_cart_outlined,
        iconColor: Colors.green,
        title: "Buy & Sell Easily",
        subtitle: "Trade products with nearby sellers",
        buttonText: "Next",
      ),
      _OnboardPage(
        icon: Icons.auto_awesome,
        iconColor: Colors.deepPurple,
        title: "Fair Prices with AI",
        subtitle: "Get smart price suggestions",
        buttonText: "Next",
      ),
      _OnboardPage(
        icon: Icons.wifi_off,
        iconColor: Colors.blue,
        title: "Work Offline",
        subtitle: "Use app without internet",
        buttonText: "Get Started",
      ),
    ];
  }

  String _skipText(AppLang lang) {
    if (lang == AppLang.ta) return "தவிர்க்க";
    if (lang == AppLang.si) return "මඟ හරින්න";
    return "Skip";
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
        // ✅ Reset to first page when language changes
        if (_lastLang != lang) {
          _lastLang = lang;
          _index = 0;

          // jump to page 0 safely after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _controller.jumpToPage(0);
          });
        }

        final pages = _pagesFor(lang);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10, top: 4),
                    child: TextButton(
                      onPressed: _goLogin,
                      child: Text(
                        _skipText(lang),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (i) {
                      if (!mounted) return;
                      setState(() => _index = i);
                    },
                    itemBuilder: (context, i) => _OnboardingBody(page: pages[i]),
                  ),
                ),

                SmoothPageIndicator(
                  controller: _controller,
                  count: pages.length,
                  effect: const ExpandingDotsEffect(
                    expansionFactor: 3,
                    dotHeight: 7,
                    dotWidth: 7,
                    spacing: 6,
                    activeDotColor: Color(0xFF2BB673),
                    dotColor: Color(0xFFBDBDBD),
                  ),
                ),

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
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
                      child: ElevatedButton(
                        onPressed: () => _next(pages.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          pages[_index].buttonText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingBody extends StatelessWidget {
  final _OnboardPage page;
  const _OnboardingBody({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            child: Icon(page.icon, size: 120, color: page.iconColor),
          ),
          const SizedBox(height: 18),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonText;

  const _OnboardPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonText,
  });
}

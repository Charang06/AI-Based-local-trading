import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_language.dart';
import '../services/voice_assistant.dart';
import 'verify_otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  bool _sending = false;
  bool _autoSpoken = false;

  @override
  void initState() {
    super.initState();

    // ✅ Auto speak once after UI loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _autoSpoken) return;
      _autoSpoken = true;
      final lang = AppLanguage.current.value;
      await _speakLoginGuide(lang);
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    VoiceAssistant.instance.stop();
    super.dispose();
  }

  String _t(AppLang lang, String key) {
    const en = {
      "welcome": "Welcome!",
      "app": "Trade Connect",
      "enter_phone": "Enter Phone Number",
      "hint": "+94 77 123 4567 or 0771234567",
      "info": "We’ll send you a code to verify your number",
      "send": "Send Code",
      "sending": "Sending OTP...",
      "timeout": "Timeout. Try again.",
      "invalid_phone":
          "Enter a valid Sri Lanka number.\nExample: +94771234567 or 0771234567",
      "failed": "Failed:",
      "help": "Help",
      "stop": "Stop",
    };

    const si = {
      "welcome": "සාදරයෙන් පිළිගනිමු!",
      "app": "Trade Connect",
      "enter_phone": "දුරකථන අංකය ඇතුළත් කරන්න",
      "hint": "+94 77 123 4567 හෝ 0771234567",
      "info": "ඔබගේ අංකය තහවුරු කිරීමට කේතයක් යවමු",
      "send": "කේතය යවන්න",
      "sending": "OTP යවමින්...",
      "timeout": "කාලය අවසන්. නැවත උත්සාහ කරන්න.",
      "invalid_phone":
          "වලංගු ශ්‍රී ලංකා අංකයක් දාන්න.\nඋදා: +94771234567 හෝ 0771234567",
      "failed": "අසාර්ථකයි:",
      "help": "උදව්",
      "stop": "නවතන්න",
    };

    const ta = {
      "welcome": "வரவேற்பு!",
      "app": "Trade Connect",
      "enter_phone": "தொலைபேசி எண்ணை உள்ளிடவும்",
      "hint": "+94 77 123 4567 அல்லது 0771234567",
      "info": "உங்கள் எண்ணை சரிபார்க்க ஒரு குறியீட்டை அனுப்புகிறோம்",
      "send": "குறியீட்டை அனுப்பவும்",
      "sending": "OTP அனுப்புகிறது...",
      "timeout": "நேரம் முடிந்தது. மீண்டும் முயற்சி செய்யவும்.",
      "invalid_phone":
          "சரியான இலங்கை எண்ணை உள்ளிடவும்.\nஉதா: +94771234567 அல்லது 0771234567",
      "failed": "தோல்வி:",
      "help": "உதவி",
      "stop": "நிறுத்து",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  String _ttsLangCode(AppLang lang) {
    if (lang == AppLang.si) return "si-LK";
    if (lang == AppLang.ta) return "ta-IN";
    return "en-US";
  }

  Future<void> _speakLoginGuide(AppLang lang) async {
    final langCode = _ttsLangCode(lang);

    String text;
    if (lang == AppLang.si) {
      text =
          "මෙය ලොගින් තිරයයි. ඔබගේ දුරකථන අංකය ඇතුළත් කර කේතය යවන්න බොත්තම ඔබන්න. "
          "උදාහරණයක් ලෙස +9477 සෑමවෙනි අංක 9ක්, හෝ 077 ලෙස අංකය ඇතුළත් කළ හැක. "
          "Stop බොත්තමෙන් කථනය නවතන්න.";
    } else if (lang == AppLang.ta) {
      text =
          "இது உள்நுழைவு திரை. உங்கள் தொலைபேசி எண்ணை உள்ளிட்டு குறியீட்டை அனுப்பவும். "
          "உதாரணம்: +9477 பிறகு 9 இலக்கங்கள், அல்லது 077 என தொடங்கி 9 இலக்கங்கள். "
          "Stop மூலம் பேசுவதை நிறுத்தலாம்.";
    } else {
      text =
          "This is the login screen. Enter your phone number and tap Send Code. "
          "Example: +9477 followed by 9 digits, or 077 followed by 9 digits. "
          "Tap Stop to cancel speaking.";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  /// ✅ Accepts:
  /// - +94771234567 (12 chars)
  /// - 0771234567 (10 chars)  -> converts to +94771234567
  /// Also removes spaces, dashes.
  String? _normalizeSriLankaPhone(String input) {
    final s = input.trim().replaceAll(RegExp(r'[\s\-()]'), '');

    // +94XXXXXXXXX (country code + 9 digits)
    final plus94 = RegExp(r'^\+94\d{9}$');
    if (plus94.hasMatch(s)) return s;

    // 0XXXXXXXXX (10 digits starting 0) -> +94 + last 9 digits
    final local = RegExp(r'^0\d{9}$');
    if (local.hasMatch(s)) {
      return "+94${s.substring(1)}";
    }

    return null;
  }

  Future<void> _sendOtp(AppLang lang) async {
    if (_sending) return;

    final raw = phoneController.text;
    final normalized = _normalizeSriLankaPhone(raw);

    if (normalized == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "invalid_phone"))));
      return;
    }

    // Update textbox to normalized format (nice UX)
    phoneController.text = normalized;

    setState(() => _sending = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_t(lang, "sending"))));

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: normalized,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (cred) {
        debugPrint("✅ verificationCompleted");
      },

      verificationFailed: (e) {
        debugPrint("❌ verificationFailed: ${e.code} - ${e.message}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${_t(lang, "failed")} ${e.message ?? e.code}"),
          ),
        );
        setState(() => _sending = false);
      },

      codeSent: (verificationId, resendToken) {
        debugPrint("✅ codeSent: $verificationId");
        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        setState(() => _sending = false);

        Future.microtask(() {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyOtpScreen(verificationId: verificationId),
            ),
          );
        });
      },

      codeAutoRetrievalTimeout: (verificationId) {
        debugPrint("⏳ timeout: $verificationId");
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_t(lang, "timeout"))));
        setState(() => _sending = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
        return Scaffold(
          // ✅ Help + Stop (voice)
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: "stop_login",
                onPressed: () => VoiceAssistant.instance.stop(),
                backgroundColor: Colors.black87,
                child: const Icon(Icons.stop, color: Colors.white),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: "help_login",
                onPressed: () => _speakLoginGuide(lang),
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
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF4FFFA), Color(0xFFEFF7FF)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE7F6FF),
                        ),
                        child: const Center(
                          child: Text("🤝", style: TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        _t(lang, "welcome"),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _t(lang, "app"),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _t(lang, "enter_phone"),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        enabled: !_sending,
                        decoration: InputDecoration(
                          hintText: _t(lang, "hint"),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFB7E2CC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2BB673),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            size: 16,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _t(lang, "info"),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2BB673), Color(0xFF2A7BF4)],
                            ),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            onPressed: _sending ? null : () => _sendOtp(lang),
                            child: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _t(lang, "send"),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 80), // space for FABs
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

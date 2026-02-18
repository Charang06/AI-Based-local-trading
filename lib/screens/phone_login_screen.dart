import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_language.dart';
import 'verify_otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  String _t(AppLang lang, String key) {
    const en = {
      "welcome": "Welcome!",
      "app": "Trade Connect",
      "enter_phone": "Enter Phone Number",
      "hint": "+94 XX XXX XXXX",
      "info": "We’ll send you a code to verify your number",
      "send": "Send Code",
      "enter_like": "Enter like +94771234567",
      "sending": "Sending OTP...",
      "sent": "OTP Sent ✅",
      "timeout": "Timeout. Try again.",
    };

    const si = {
      "welcome": "සාදරයෙන් පිළිගනිමු!",
      "app": "Trade Connect",
      "enter_phone": "දුරකථන අංකය ඇතුළත් කරන්න",
      "hint": "+94 XX XXX XXXX",
      "info": "ඔබගේ අංකය තහවුරු කිරීමට කේතයක් යවමු",
      "send": "කේතය යවන්න",
      "enter_like": "මෙම ලෙස ඇතුළත් කරන්න +94771234567",
      "sending": "OTP යවමින්...",
      "sent": "OTP යවලා ✅",
      "timeout": "කාලය අවසන්. නැවත උත්සාහ කරන්න.",
    };

    const ta = {
      "welcome": "வரவேற்பு!",
      "app": "Trade Connect",
      "enter_phone": "தொலைபேசி எண்ணை உள்ளிடவும்",
      "hint": "+94 XX XXX XXXX",
      "info": "உங்கள் எண்ணை சரிபார்க்க ஒரு குறியீட்டை அனுப்புகிறோம்",
      "send": "குறியீட்டை அனுப்பவும்",
      "enter_like": "இந்த மாதிரி உள்ளிடுங்கள் +94771234567",
      "sending": "OTP அனுப்புகிறது...",
      "sent": "OTP அனுப்பப்பட்டது ✅",
      "timeout": "நேரம் முடிந்தது. மீண்டும் முயற்சி செய்யவும்.",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  Future<void> _sendOtp(AppLang lang) async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty || !phone.startsWith("+")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(lang, "enter_like"))),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t(lang, "sending"))),
    );

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (cred) {
        debugPrint("✅ verificationCompleted");
      },

      verificationFailed: (e) {
        debugPrint("❌ verificationFailed: ${e.code} - ${e.message}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${e.message ?? e.code}")),
        );
      },

      codeSent: (verificationId, resendToken) {
        debugPrint("✅ codeSent: $verificationId");
        if (!mounted) return;

        // remove snackbar so push works smoothly
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // ✅ Navigate safely after current frame
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t(lang, "timeout"))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
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
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                        decoration: InputDecoration(
                          hintText: _t(lang, "hint"),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFB7E2CC)),
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
                          const Icon(Icons.verified_outlined, size: 16, color: Colors.black54),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _t(lang, "info"),
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
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
                            onPressed: () => _sendOtp(lang),
                            child: Text(
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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_language.dart';
import 'home_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String verificationId;

  const VerifyOtpScreen({super.key, required this.verificationId});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController otpController = TextEditingController();

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  String _t(AppLang lang, String key) {
    const en = {
      "title": "Verify OTP",
      "label": "Enter OTP",
      "btn": "Verify",
      "hint": "6-digit code",
      "invalid": "Enter the 6-digit OTP",
      "failed": "OTP Failed",
    };

    const si = {
      "title": "OTP තහවුරු කිරීම",
      "label": "OTP ඇතුළත් කරන්න",
      "btn": "තහවුරු කරන්න",
      "hint": "අංක 6 ක කේතය",
      "invalid": "අංක 6 ක OTP එක ඇතුළත් කරන්න",
      "failed": "OTP අසාර්ථකයි",
    };

    const ta = {
      "title": "OTP சரிபார்ப்பு",
      "label": "OTP ஐ உள்ளிடவும்",
      "btn": "சரிபார்க்க",
      "hint": "6 இலக்க குறியீடு",
      "invalid": "6 இலக்க OTP ஐ உள்ளிடவும்",
      "failed": "OTP தோல்வி",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  Future<void> _verify(AppLang lang) async {
    final code = otpController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(lang, "invalid"))),
      );
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${_t(lang, "failed")}: $e")),
      );
    }
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
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    // Simple top bar
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Expanded(
                          child: Text(
                            _t(lang, "title"),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // balance for back icon
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Icon
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE7F6FF),
                      ),
                      child: const Center(
                        child: Icon(Icons.lock_outline, size: 30),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _t(lang, "label"),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: _t(lang, "hint"),
                        prefixIcon: const Icon(Icons.password_outlined),
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

                    const SizedBox(height: 18),

                    // Gradient verify button (same style)
                    SizedBox(
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
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _verify(lang),
                          child: Text(
                            _t(lang, "btn"),
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
        );
      },
    );
  }
}

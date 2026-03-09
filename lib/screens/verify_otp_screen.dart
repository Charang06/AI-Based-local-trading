import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../app_language.dart';
import '../services/voice_assistant.dart';
import 'home_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String verificationId;

  const VerifyOtpScreen({super.key, required this.verificationId});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController otpController = TextEditingController();
  final FocusNode _otpFocus = FocusNode();

  bool _verifying = false;

  // ✅ Voice
  bool _autoSpoken = false;

  @override
  void initState() {
    super.initState();

    // auto focus
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _otpFocus.requestFocus();

      // auto speak once
      if (_autoSpoken) return;
      _autoSpoken = true;
      final lang = AppLanguage.current.value;
      await _speakOtpGuide(lang);
    });
  }

  @override
  void dispose() {
    otpController.dispose();
    _otpFocus.dispose();
    VoiceAssistant.instance.stop();
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
      "verifying": "Verifying...",
      "help": "Help",
      "stop": "Stop",
      "login_success": "Logged in ✅",
    };

    const si = {
      "title": "OTP තහවුරු කිරීම",
      "label": "OTP ඇතුළත් කරන්න",
      "btn": "තහවුරු කරන්න",
      "hint": "අංක 6 ක කේතය",
      "invalid": "අංක 6 ක OTP එක ඇතුළත් කරන්න",
      "failed": "OTP අසාර්ථකයි",
      "verifying": "තහවුරු කරමින්...",
      "help": "උදව්",
      "stop": "නවතන්න",
      "login_success": "ලොගින් වුණා ✅",
    };

    const ta = {
      "title": "OTP சரிபார்ப்பு",
      "label": "OTP ஐ உள்ளிடவும்",
      "btn": "சரிபார்க்க",
      "hint": "6 இலக்க குறியீடு",
      "invalid": "6 இலக்க OTP ஐ உள்ளிடவும்",
      "failed": "OTP தோல்வி",
      "verifying": "சரிபார்க்கிறது...",
      "help": "உதவி",
      "stop": "நிறுத்து",
      "login_success": "உள்நுழைந்தது ✅",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  String _ttsLangCode(AppLang lang) {
    if (lang == AppLang.si) return "si-LK";
    if (lang == AppLang.ta) return "ta-IN";
    return "en-US";
  }

  Future<void> _speakOtpGuide(AppLang lang) async {
    final langCode = _ttsLangCode(lang);

    String text;
    if (lang == AppLang.si) {
      text =
          "OTP තහවුරු කිරීමේ තිරයයි. ඔබට ලැබුණු අංක හයයි OTP එක මෙහි ඇතුළත් කර තහවුරු කරන්න බොත්තම ඔබන්න.";
    } else if (lang == AppLang.ta) {
      text =
          "இது OTP சரிபார்ப்பு திரை. உங்களுக்கு வந்த 6 இலக்க OTP ஐ உள்ளிட்டு சரிபார்க்க பொத்தானை அழுத்தவும்.";
    } else {
      text =
          "This is the OTP verification screen. Enter the 6-digit code you received and tap Verify.";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  bool _isValidOtp(String s) => RegExp(r'^\d{6}$').hasMatch(s.trim());

  Future<void> _verify(AppLang lang) async {
    final code = otpController.text.trim();

    if (!_isValidOtp(code)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "invalid"))));
      return;
    }

    if (_verifying) return;
    setState(() => _verifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "login_success"))));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${_t(lang, "failed")}: $e")));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
        return Scaffold(
          // ✅ Voice buttons
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: "stop_otp",
                onPressed: () => VoiceAssistant.instance.stop(),
                backgroundColor: Colors.black87,
                child: const Icon(Icons.stop, color: Colors.white),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: "help_otp",
                onPressed: () => _speakOtpGuide(lang),
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
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    // Top bar
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
                        const SizedBox(width: 48),
                      ],
                    ),

                    const SizedBox(height: 30),

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
                      focusNode: _otpFocus,
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      enabled: !_verifying,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _verifying ? null : _verify(lang),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: _t(lang, "hint"),
                        prefixIcon: const Icon(Icons.password_outlined),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
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
                          onPressed: _verifying ? null : () => _verify(lang),
                          child: _verifying
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _t(lang, "verifying"),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
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

                    const SizedBox(height: 80), // space for FAB
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

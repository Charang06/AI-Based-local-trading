import 'package:flutter/foundation.dart';

enum AppLang { en, si, ta }

class I18n {
  static final ValueNotifier<AppLang> lang = ValueNotifier(AppLang.en);

  static void setLang(AppLang l) => lang.value = l;

  // ---- Text dictionary ----
  static const Map<AppLang, Map<String, String>> _t = {
    AppLang.en: {
      "select_language": "Select Your Language",
      "choose_language": "Choose your preferred language",
      "skip": "Skip",
      "next": "Next",
      "get_started": "Get Started",

      "ob1_title": "Buy & Sell Easily",
      "ob1_sub": "Trade products with nearby sellers",
      "ob2_title": "Fair Prices with AI",
      "ob2_sub": "Get smart price suggestions",
      "ob3_title": "Work Offline",
      "ob3_sub": "Use app without internet",

      "welcome": "Welcome!",
      "app_name": "Trade Connect",
      "enter_phone": "Enter Phone Number",
      "phone_hint": "+94 XX XXX XXXX",
      "verify_info": "We’ll send you a code to verify your number",
      "send_code": "Send Code",
      "enter_like": "Enter like +94771234567",
    },

    // Sinhala
    AppLang.si: {
      "select_language": "භාෂාව තෝරන්න",
      "choose_language": "ඔබ කැමති භාෂාව තෝරන්න",
      "skip": "මඟ හරින්න",
      "next": "ඊළඟ",
      "get_started": "ආරම්භ කරන්න",

      "ob1_title": "ලේසියෙන් මිලදී ගන්න\nසැණින් විකුණන්න",
      "ob1_sub": "ළඟම විකිණුම්කරුවන් සමඟ\nභාණ්ඩ ගනුදෙනු කරන්න",
      "ob2_title": "AI සමඟ සාධාරණ\nමිල ගණන්",
      "ob2_sub": "හොඳම මිල යෝජනා ලබා ගන්න",
      "ob3_title": "අන්තර්ජාලය නැතිවත්\nභාවිතා කරන්න",
      "ob3_sub": "ඕෆ්ලයින්දීත් යෙදුම භාවිතා කළ හැක",

      "welcome": "සාදරයෙන් පිළිගනිමු!",
      "app_name": "Trade Connect",
      "enter_phone": "දුරකථන අංකය ඇතුළත් කරන්න",
      "phone_hint": "+94 XX XXX XXXX",
      "verify_info": "ඔබගේ අංකය තහවුරු කිරීමට කේතයක් යවමු",
      "send_code": "කේතය යවන්න",
      "enter_like": "මෙම ලෙස ඇතුළත් කරන්න +94771234567",
    },

    // Tamil (based on your UI style)
    AppLang.ta: {
      "select_language": "மொழியைத் தேர்ந்தெடுக்கவும்",
      "choose_language": "உங்கள் விருப்பமான மொழியை தேர்ந்தெடுக்கவும்",
      "skip": "தவிர்க்க",
      "next": "அடுத்து",
      "get_started": "தொடங்குங்கள்",

      "ob1_title": "எளிதாக வாங்கவும்\nவிற்கவும்",
      "ob1_sub": "அருகிலுள்ள விற்பனையாளர்களுடன்\nபொருட்களை வாங்கவும், விற்கவும்",
      "ob2_title": "AI உடன் நியாயமான\nவிலைகள்",
      "ob2_sub": "சிறந்த விலை பரிந்துரைகள் பெறுங்கள்",
      "ob3_title": "ஆஃப்லைனிலும்\nபயன்படுத்து",
      "ob3_sub": "இணையம் இல்லாமலும் செயலியை பயன்படுத்தலாம்",

      "welcome": "வரவேற்பு!",
      "app_name": "Trade Connect",
      "enter_phone": "தொலைபேசி எண்ணை உள்ளிடவும்",
      "phone_hint": "+94 XX XXX XXXX",
      "verify_info": "உங்கள் எண்ணை சரிபார்க்க ஒரு குறியீட்டை அனுப்புகிறோம்",
      "send_code": "குறியீட்டை அனுப்பவும்",
      "enter_like": "இந்த மாதிரி உள்ளிடுங்கள் +94771234567",
    },
  };

  static String tr(String key) => _t[lang.value]?[key] ?? key;
}

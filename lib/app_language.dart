import 'package:flutter/foundation.dart';

enum AppLang { en, si, ta }

class AppLanguage {
  static final ValueNotifier<AppLang> current = ValueNotifier(AppLang.en);

  static void setLang(AppLang lang) {
    current.value = lang;
  }
}

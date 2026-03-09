import 'package:hive_flutter/hive_flutter.dart';

class AiTipsService {
  static const _boxName = "ai_tips_box";
  static const _kLastDate = "last_date";
  static const _kTipIndex = "tip_index";

  // Your weekly tips list (or you can add more)
  static const List<String> tips = [
    "🌾 Rice prices are 8% lower this week. Good time to buy!",
    "📸 Products with 3+ photos sell 2x faster. Add more images!",
    "💰 Your prices are competitive! Keep negotiating for best deals.",
    "⏰ Most buyers shop 8–11 AM. Post products in the morning!",
    "🤝 Accepting offers near AI price increases your sales by 40%.",
    "⭐ Sellers with 4.5+ rating sell more. Deliver quality!",
    "📊 Review your week: check sold items and earnings.",
  ];

  static Future<Box> _box() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  static String _todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// ✅ Always returns the SAME tip for the same day
  static Future<String> getTodayTip() async {
    final box = await _box();
    final today = _todayKey();

    final lastDate = box.get(_kLastDate) as String?;
    final savedIndex = box.get(_kTipIndex) as int?;

    if (lastDate == today && savedIndex != null) {
      return tips[savedIndex % tips.length];
    }

    // New day → choose deterministic index
    // (Use weekday OR use day number modulo length)
    final index = DateTime.now().weekday - 1; // Mon=0..Sun=6

    await box.put(_kLastDate, today);
    await box.put(_kTipIndex, index);

    return tips[index % tips.length];
  }

  /// Optional: if you want a manual "Next" button that cycles tips
  /// BUT still stays same after refresh (saved in Hive).
  static Future<String> nextTip() async {
    final box = await _box();
    final today = _todayKey();

    final lastDate = box.get(_kLastDate) as String?;
    int index = (box.get(_kTipIndex) as int?) ?? 0;

    if (lastDate != today) {
      // reset for new day first
      await box.put(_kLastDate, today);
      index = DateTime.now().weekday - 1;
    } else {
      index = (index + 1) % tips.length;
    }

    await box.put(_kTipIndex, index);
    return tips[index];
  }
}

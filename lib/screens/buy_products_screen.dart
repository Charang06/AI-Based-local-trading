import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../app_language.dart';
import '../models/product.dart';
import '../services/voice_assistant.dart';
import 'product_detail_screen.dart';

class BuyProductsScreen extends StatefulWidget {
  const BuyProductsScreen({super.key});

  @override
  State<BuyProductsScreen> createState() => _BuyProductsScreenState();
}

class _BuyProductsScreenState extends State<BuyProductsScreen> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();

  // Filters
  bool fairDealOnly = false;
  double maxDistanceKm = 10;
  int minPrice = 0;
  int maxPrice = 1000000;
  double minSellerRating = 0;

  // Internal values (keep English for DB/filtering)
  String selectedCategory = "All";
  final List<String> categories = const [
    "All",
    "Food & Vegetables",
    "Electronics",
    "Vehicles",
    "Home & Living",
    "Fashion",
    "Services",
  ];

  String selectedLocation = "All";

  static const List<String> districts = [
    "Ampara",
    "Anuradhapura",
    "Badulla",
    "Batticaloa",
    "Colombo",
    "Galle",
    "Gampaha",
    "Hambantota",
    "Jaffna",
    "Kalutara",
    "Kandy",
    "Kegalle",
    "Kilinochchi",
    "Kurunegala",
    "Mannar",
    "Monaragala",
    "Mullaitivu",
    "Nuwara Eliya",
    "Polonnaruwa",
    "Puttalam",
    "Ratnapura",
    "Trincomalee",
    "Vavuniya",
    "Matale",
    "Matara",
  ];

  // Cache
  static const String _cacheBox = "products_cache";
  static const String _cacheKey = "latest_products";

  // Speech To Text
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _listeningSearch = false;

  // Voice auto speak
  bool _autoSpoken = false;

  // Filter guide auto once per open
  bool _filterHelpSpoken = false;

  // No products auto voice (avoid repeats)
  bool _noProductsSpoken = false;
  String _noProductsSignature = "";

  // Visible reading
  List<Product> _currentProducts = const [];

  // For visible read calculation (approx)
  static const double _cardExtent = 320;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _autoSpoken) return;
      _autoSpoken = true;
      final lang = AppLanguage.current.value;
      await _speakBuyGuide(lang);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();

    // Stop STT safely
    try {
      _stt.stop();
    } catch (_) {}

    // Stop voice safely
    VoiceAssistant.instance.stop();
    super.dispose();
  }

  DateTime? _tsToDate(dynamic v) => v is Timestamp ? v.toDate() : null;

  // =========================
  // ✅ UI Translations
  // =========================
  String _t(AppLang lang, String key) {
    const en = {
      "title": "Buy Products",
      "search": "Search products...",
      "filters": "Filters",
      "fair_only": "Fair Deal only",
      "max_distance": "Max Distance",
      "price_range": "Price Range (Rs)",
      "apply": "Apply Filters",
      "all_products": "All Products",
      "products_count": "products",
      "no_products": "No products found",
      "fair_deal": "Fair Deal",
      "check": "Check",
      "ai": "AI",
      "km": "km",
      "category": "Category",
      "all": "All",
      "rating": "Min Seller Rating",
      "location": "Location",
      "offline_cached": "Offline mode: showing cached products",
      "help": "Help",
      "stop": "Stop",
      "read": "Read",
      "voice_not_available": "Voice input not available on this device.",
      "filter_help_title": "Filter Help",
    };

    const si = {
      "title": "භාණ්ඩ මිලදී ගන්න",
      "search": "භාණ්ඩ සොයන්න...",
      "filters": "ෆිල්ටර්",
      "fair_only": "සාධාරණ ගනුදෙනු පමණක්",
      "max_distance": "උපරිම දුර",
      "price_range": "මිල පරාසය (රු.)",
      "apply": "ෆිල්ටර් යොදන්න",
      "all_products": "සියලු භාණ්ඩ",
      "products_count": "භාණ්ඩ",
      "no_products": "භාණ්ඩ නොමැත",
      "fair_deal": "සාධාරණයි",
      "check": "පරීක්ෂා කරන්න",
      "ai": "AI",
      "km": "කි.මී",
      "category": "වර්ගය",
      "all": "සියල්ල",
      "rating": "අවම විකුණුම්කරු අගය",
      "location": "ස්ථානය",
      "offline_cached": "Offline: කැෂ් කළ භාණ්ඩ පෙන්වයි",
      "help": "උදව්",
      "stop": "නවතන්න",
      "read": "කියවන්න",
      "voice_not_available": "මෙම දුරකථනයේ හඬ ආදානය නොමැත.",
      "filter_help_title": "ෆිල්ටර් උදව්",
    };

    const ta = {
      "title": "பொருட்கள் வாங்கவும்",
      "search": "பொருட்களை தேடுங்கள்...",
      "filters": "வடிகட்டிகள்",
      "fair_only": "நல்ல விலை மட்டும்",
      "max_distance": "அதிகபட்ச தூரம்",
      "price_range": "விலை வரம்பு (ரூ.)",
      "apply": "வடிகட்டிகளை பயன்படுத்து",
      "all_products": "அனைத்து பொருட்கள்",
      "products_count": "பொருட்கள்",
      "no_products": "பொருட்கள் கிடைக்கவில்லை",
      "fair_deal": "நல்ல விலை",
      "check": "சரி பார்க்க",
      "ai": "AI",
      "km": "கிமீ",
      "category": "வகை",
      "all": "அனைத்து",
      "rating": "குறைந்தபட்ச விற்பனையாளர் மதிப்பீடு",
      "location": "இடம்",
      "offline_cached": "Offline: கேஷ் செய்யப்பட்ட பொருட்கள்",
      "help": "உதவி",
      "stop": "நிறுத்து",
      "read": "படிக்க",
      "voice_not_available": "இந்த சாதனத்தில் குரல் உள்ளீடு இல்லை.",
      "filter_help_title": "வடிகட்டி உதவி",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  // =========================
  // ✅ Category label translation (UI only)
  // =========================
  String _categoryToLabel(AppLang lang, String internal) {
    if (lang == AppLang.si) {
      switch (internal) {
        case "All":
          return "සියල්ල";
        case "Food & Vegetables":
          return "ආහාර සහ එළවළු";
        case "Electronics":
          return "විදුලි උපකරණ";
        case "Vehicles":
          return "වාහන";
        case "Home & Living":
          return "ගෘහ භාණ්ඩ";
        case "Fashion":
          return "විලාසිතා";
        case "Services":
          return "සේවාවන්";
      }
    }
    if (lang == AppLang.ta) {
      switch (internal) {
        case "All":
          return "அனைத்து";
        case "Food & Vegetables":
          return "உணவு & காய்கறிகள்";
        case "Electronics":
          return "மின்சாதனங்கள்";
        case "Vehicles":
          return "வாகனங்கள்";
        case "Home & Living":
          return "வீட்டு பொருட்கள்";
        case "Fashion":
          return "ஃபேஷன்";
        case "Services":
          return "சேவைகள்";
      }
    }
    return internal;
  }

  String _labelToCategory(AppLang lang, String label) {
    for (final c in categories) {
      if (_categoryToLabel(lang, c) == label) return c;
    }
    return "All";
  }

  // =========================
  // ✅ District label translation (UI only)
  // =========================
  String _districtToLabel(AppLang lang, String d) {
    if (d == "All") return _t(lang, "all");

    if (lang == AppLang.si) {
      const m = {
        "Colombo": "කොළඹ",
        "Gampaha": "ගම්පහ",
        "Kalutara": "කළුතර",
        "Kandy": "මහනුවර",
        "Galle": "ගාල්ල",
        "Matara": "මාතර",
        "Jaffna": "යාපනය",
        "Batticaloa": "මඩකලපුව",
        "Trincomalee": "ත්‍රිකුණාමලය",
        "Anuradhapura": "අනුරාධපුර",
        "Kurunegala": "කුරුණෑගල",
        "Ratnapura": "රත්නපුර",
        "Badulla": "බදුල්ල",
        "Kegalle": "කෑගල්ල",
        "Puttalam": "පුත්තලම",
        "Hambantota": "හම්බන්තොට",
        "Nuwara Eliya": "නුවර එළිය",
        "Polonnaruwa": "පොළොන්නරුව",
        "Vavuniya": "වව්නියාව",
        "Mannar": "මන්නාරම",
        "Kilinochchi": "කිලිනොච්චි",
        "Mullaitivu": "මුලතිව්",
        "Monaragala": "මොනරාගල",
        "Ampara": "අම්පාර",
        "Matale": "මාතලේ",
      };
      return m[d] ?? d;
    }

    if (lang == AppLang.ta) {
      const m = {
        "Colombo": "கொழும்பு",
        "Gampaha": "கம்பஹா",
        "Kalutara": "களுத்துறை",
        "Kandy": "கண்டி",
        "Galle": "காலி",
        "Matara": "மாத்தறை",
        "Jaffna": "யாழ்ப்பாணம்",
        "Batticaloa": "மட்டக்களப்பு",
        "Trincomalee": "திருகோணமலை",
        "Anuradhapura": "அனுராதபுரம்",
        "Kurunegala": "குருணாகல்",
        "Ratnapura": "இரத்தினபுரி",
        "Badulla": "பதுளை",
        "Kegalle": "கேகாலை",
        "Puttalam": "புத்தளம்",
        "Hambantota": "ஹம்பாந்தோட்டை",
        "Nuwara Eliya": "நுவரெலியா",
        "Polonnaruwa": "பொலன்னறுவா",
        "Vavuniya": "வவுனியா",
        "Mannar": "மன்னார்",
        "Kilinochchi": "கிளிநொச்சி",
        "Mullaitivu": "முல்லைத்தீவு",
        "Monaragala": "மொனராகல",
        "Ampara": "அம்பாறை",
        "Matale": "மாத்தளை",
      };
      return m[d] ?? d;
    }

    return d;
  }

  String _labelToDistrict(AppLang lang, String label) {
    if (label == _t(lang, "all")) return "All";
    for (final d in districts) {
      if (_districtToLabel(lang, d) == label) return d;
    }
    return "All";
  }

  // =========================
  // ✅ Voice
  // =========================
  String _ttsCode(AppLang lang) {
    if (lang == AppLang.si) return "si-LK";
    if (lang == AppLang.ta) return "ta-IN";
    return "en-US";
  }

  Future<void> _speakBuyGuide(AppLang lang) async {
    final langCode = _ttsCode(lang);

    String text;
    if (lang == AppLang.si) {
      text =
          "මෙය භාණ්ඩ මිලදී ගැනීමේ තිරයයි. ඉහළින් සෙවීමේ තීරුවේ භාණ්ඩ නාමය ටයිප් කරන්න හෝ මයික් එක ඔබා කියන්න. "
          "ෆිල්ටර් බොත්තමෙන් වර්ගය, දිස්ත්‍රික්කය, මිල සහ දුර තෝරන්න. කාඩ් එකක් ඔබා විස්තර බලන්න.";
    } else if (lang == AppLang.ta) {
      text =
          "இது வாங்கும் திரை. தேடல் பெட்டியில் எழுதவும் அல்லது மைக் அழுத்தி பேசவும். "
          "வடிகட்டி பொத்தானில் வகை, இடம், விலை, தூரம் தேர்வு செய்யலாம். ஒரு கார்டை தொட்டு விவரங்களை பார்க்கலாம்.";
    } else {
      text =
          "This is the Buy screen. Use search to type or tap the mic to speak. Use the filter button to select category, location, price, and distance. Tap a product card to see details.";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  Future<void> _speakFilterGuide(AppLang lang) async {
    final langCode = _ttsCode(lang);

    String text;
    if (lang == AppLang.si) {
      text =
          "වර්ගය, ස්ථානය, අවම අගය, සාධාරණ ගනුදෙනු, දුර සහ මිල පරාසය තෝරන්න. පසුව ෆිල්ටර් යොදන්න ඔබන්න.";
    } else if (lang == AppLang.ta) {
      text =
          "வகை, இடம், குறைந்த மதிப்பீடு, நல்ல விலை, தூரம் மற்றும் விலை வரம்பை தேர்வு செய்யவும். பிறகு பயன்படுத்து அழுத்தவும்.";
    } else {
      text =
          "Choose category, location, minimum rating, fair deal, distance, and price range. Then tap Apply Filters.";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  Future<void> _maybeSpeakNoProducts(AppLang lang) async {
    final sig =
        "${_search.text.trim().toLowerCase()}|$selectedCategory|$selectedLocation|$fairDealOnly|$minPrice|$maxPrice|${maxDistanceKm.toStringAsFixed(0)}|${minSellerRating.toStringAsFixed(1)}";

    if (_noProductsSpoken && _noProductsSignature == sig) return;

    _noProductsSpoken = true;
    _noProductsSignature = sig;

    final langCode = _ttsCode(lang);

    String text;
    if (lang == AppLang.si) {
      text =
          "මෙම සෙවීම සඳහා භාණ්ඩ නොමැත. සෙවීම වෙනස් කරන්න හෝ ෆිල්ටර් අඩු කරන්න.";
    } else if (lang == AppLang.ta) {
      text =
          "இந்த தேடலுக்கு பொருட்கள் இல்லை. தேடலை மாற்றவும் அல்லது வடிகட்டிகளை குறைக்கவும்.";
    } else {
      text = "No products found. Try a different search or reduce filters.";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  // =========================
  // ✅ Speech-to-text
  // =========================
  String _sttLocaleId(AppLang lang) {
    if (lang == AppLang.si) return "si_LK";
    if (lang == AppLang.ta) return "ta_IN";
    return "en_US";
  }

  Future<void> _toggleVoiceSearch(AppLang lang) async {
    if (_stt.isListening) {
      try {
        await _stt.stop();
      } catch (_) {}
      if (!mounted) return;
      setState(() => _listeningSearch = false);
      return;
    }

    final ok = await _stt.initialize(onStatus: (_) {}, onError: (_) {});

    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "voice_not_available"))));
      return;
    }

    if (!mounted) return;
    setState(() => _listeningSearch = true);

    await _stt.listen(
      localeId: _sttLocaleId(lang),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
      onResult: (res) {
        if (!mounted) return;

        _search.text = res.recognizedWords;
        _search.selection = TextSelection.fromPosition(
          TextPosition(offset: _search.text.length),
        );
        _noProductsSpoken = false;

        setState(() {});

        if (res.finalResult) {
          setState(() => _listeningSearch = false);
        }
      },
    );
  }

  Future<void> _speakProduct(Product p, AppLang lang) async {
    final langCode = _ttsCode(lang);
    final loc = _districtToLabel(lang, p.locationName);

    String text;
    if (lang == AppLang.si) {
      text =
          "${p.title}. මිල රුපියල් ${p.priceRs}. ප්‍රමාණය ${p.qty} ${p.unit}. ස්ථානය $loc. "
          "${p.fairDeal ? "මෙය සාධාරණ ගනුදෙනුවක්. " : ""}"
          "${p.aiPriceRs > 0 ? "AI මිල රුපියල් ${p.aiPriceRs}." : ""}";
    } else if (lang == AppLang.ta) {
      text =
          "${p.title}. விலை ரூபாய் ${p.priceRs}. அளவு ${p.qty} ${p.unit}. இடம் $loc. "
          "${p.fairDeal ? "இது நல்ல விலை. " : ""}"
          "${p.aiPriceRs > 0 ? "AI விலை ரூபாய் ${p.aiPriceRs}." : ""}";
    } else {
      text =
          "${p.title}. Price rupees ${p.priceRs}. Quantity ${p.qty} ${p.unit}. Location $loc. "
          "${p.fairDeal ? "This is a fair deal. " : ""}"
          "${p.aiPriceRs > 0 ? "AI price is ${p.aiPriceRs}." : ""}";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  Future<void> _readVisibleNow(AppLang lang) async {
    if (_currentProducts.isEmpty) return;

    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    final firstVisibleCardIndex = (offset / _cardExtent).floor();
    final start = firstVisibleCardIndex.clamp(0, _currentProducts.length - 1);

    final items = _currentProducts.skip(start).take(5).toList();
    final langCode = _ttsCode(lang);

    String text;
    if (lang == AppLang.si) {
      text = "පෙන්වෙන භාණ්ඩ: ";
      for (final p in items) {
        text += "${p.title}, රුපියල් ${p.priceRs}. ";
      }
    } else if (lang == AppLang.ta) {
      text = "காணப்படும் பொருட்கள்: ";
      for (final p in items) {
        text += "${p.title}, ரூபாய் ${p.priceRs}. ";
      }
    } else {
      text = "Visible products: ";
      for (final p in items) {
        text += "${p.title}, price ${p.priceRs}. ";
      }
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  // =========================
  // ✅ Product mapping & filters
  // =========================
  Product _fromMap(String id, Map<String, dynamic> d) {
    return Product(
      id: id,
      title: (d["title"] ?? "").toString(),
      imageUrl: (d["imageUrl"] ?? "").toString(),
      priceRs: (d["priceRs"] as num?)?.toInt() ?? 0,
      qty: (d["qty"] as num?)?.toDouble() ?? 1,
      unit: (d["unit"] ?? "unit").toString(),
      baseQty: (d["baseQty"] as num?)?.toDouble() ?? 1,
      baseUnit: (d["baseUnit"] ?? "unit").toString(),
      pricePerBase: (d["pricePerBase"] as num?)?.toDouble() ?? 0,
      aiPriceRs: (d["aiPriceRs"] as num?)?.toInt() ?? 0,
      fairDeal: (d["fairDeal"] as bool?) ?? false,
      marketLow: (d["marketLow"] as num?)?.toInt() ?? 0,
      marketHigh: (d["marketHigh"] as num?)?.toInt() ?? 0,
      sellerId: (d["sellerId"] ?? "").toString(),
      sellerName: (d["sellerName"] ?? "").toString(),
      sellerPhone: (d["sellerPhone"] ?? "").toString(),
      sellerRating: (d["sellerRating"] as num?)?.toDouble() ?? 0,
      distanceKm: (d["distanceKm"] as num?)?.toDouble() ?? 0,
      locationName: (d["locationName"] ?? "Unknown").toString(),
      lat: (d["lat"] as num?)?.toDouble() ?? 0,
      lng: (d["lng"] as num?)?.toDouble() ?? 0,
      description: (d["description"] ?? "").toString(),
      tags: List<String>.from(d["tags"] ?? const []),
      category: (d["category"] ?? "Other").toString(),
      status: (d["status"] ?? "active").toString(),
      createdAt: _tsToDate(d["createdAt"]),
      soldAt: _tsToDate(d["soldAt"]),
    );
  }

  Product _fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return _fromMap(doc.id, d);
  }

  List<Product> _applyFilters(List<Product> products) {
    final q = _search.text.trim().toLowerCase();

    return products.where((p) {
      if (p.status != "active") return false;

      if (q.isNotEmpty && !p.title.toLowerCase().contains(q)) return false;
      if (fairDealOnly && !p.fairDeal) return false;
      if (p.distanceKm > maxDistanceKm) return false;
      if (p.priceRs < minPrice || p.priceRs > maxPrice) return false;

      if (selectedCategory != "All" && p.category != selectedCategory) {
        return false;
      }
      if (p.sellerRating < minSellerRating) return false;
      if (selectedLocation != "All" && p.locationName != selectedLocation) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _saveProductsToCache(List<QueryDocumentSnapshot> docs) async {
    try {
      if (!Hive.isBoxOpen(_cacheBox)) return;
      final box = Hive.box(_cacheBox);

      final list = docs.map((d) {
        final data = (d.data() as Map<String, dynamic>);
        return {"id": d.id, ...data};
      }).toList();

      await box.put(_cacheKey, list);
      await box.put("${_cacheKey}_time", DateTime.now().toIso8601String());
    } catch (_) {}
  }

  List<Product> _loadProductsFromCache() {
    try {
      if (!Hive.isBoxOpen(_cacheBox)) return [];
      final box = Hive.box(_cacheBox);
      final raw = box.get(_cacheKey);

      if (raw is! List) return [];
      return raw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final id = (m["id"] ?? "").toString();
        m.remove("id");
        return _fromMap(id, m);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  void _openFilter(AppLang lang) {
    _noProductsSpoken = false;
    _filterHelpSpoken = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_filterHelpSpoken) return;
            _filterHelpSpoken = true;
            _speakFilterGuide(lang);
          });

          final categoryItems = categories
              .map((c) => _categoryToLabel(lang, c))
              .toList();

          final locationItems = <String>[
            _t(lang, "all"),
            ...districts.map((d) => _districtToLabel(lang, d)),
          ];

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _t(lang, "filters"),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _t(lang, "filter_help_title"),
                      onPressed: () => _speakFilterGuide(lang),
                      icon: const Icon(
                        Icons.volume_up_outlined,
                        color: Color(0xFF2A7BF4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _t(lang, "category"),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 8),
                _dropdownBox(
                  value: _categoryToLabel(lang, selectedCategory),
                  items: categoryItems,
                  onChanged: (label) => setSheet(() {
                    selectedCategory = _labelToCategory(lang, label);
                  }),
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _t(lang, "location"),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 8),
                _dropdownBox(
                  value: (selectedLocation == "All")
                      ? _t(lang, "all")
                      : _districtToLabel(lang, selectedLocation),
                  items: locationItems,
                  onChanged: (label) => setSheet(() {
                    selectedLocation = _labelToDistrict(lang, label);
                  }),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _t(lang, "rating"),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      minSellerRating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                Slider(
                  value: minSellerRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  onChanged: (v) => setSheet(() => minSellerRating = v),
                ),

                SwitchListTile(
                  value: fairDealOnly,
                  onChanged: (v) => setSheet(() => fairDealOnly = v),
                  title: Text(_t(lang, "fair_only")),
                ),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _t(lang, "max_distance"),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      "${maxDistanceKm.toStringAsFixed(0)} ${_t(lang, "km")}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                Slider(
                  value: maxDistanceKm,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  onChanged: (v) => setSheet(() => maxDistanceKm = v),
                ),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _t(lang, "price_range"),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      "Rs $minPrice - Rs $maxPrice",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(minPrice.toDouble(), maxPrice.toDouble()),
                  min: 0,
                  max: 1000000,
                  divisions: 200,
                  onChanged: (r) => setSheet(() {
                    minPrice = r.start.round();
                    maxPrice = r.end.round();
                  }),
                ),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      _noProductsSpoken = false;
                      setState(() {});
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A7BF4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _t(lang, "apply"),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================
  // ✅ Main UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: _FloatingButtons(
            readLabel: _t(lang, "read"),
            helpLabel: _t(lang, "help"),
            onStop: () => VoiceAssistant.instance.stop(),
            onRead: () => _readVisibleNow(lang),
            onHelp: () => _speakBuyGuide(lang),
          ),
          body: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 44, 16, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2BB673), Color(0xFF2A7BF4)],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _t(lang, "title"),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _openFilter(lang),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: Color(0xFF2A7BF4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Search + mic
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.white),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _search,
                              onChanged: (_) {
                                _noProductsSpoken = false;
                                setState(() {});
                              },
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: _t(lang, "search"),
                                hintStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: "Voice search",
                            onPressed: () => _toggleVoiceSearch(lang),
                            icon: Icon(
                              _listeningSearch ? Icons.mic : Icons.mic_none,
                              color: _listeningSearch
                                  ? Colors.yellowAccent
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("products")
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    // Online
                    if (snap.hasData) {
                      final docs = snap.data?.docs ?? [];
                      _saveProductsToCache(docs.cast<QueryDocumentSnapshot>());

                      final allProducts = docs.map(_fromDoc).toList();
                      final products = _applyFilters(allProducts);

                      _currentProducts = products;

                      if (products.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _maybeSpeakNoProducts(lang);
                        });
                        return Center(child: Text(_t(lang, "no_products")));
                      }

                      return _listBody(products, lang, showOfflineHint: false);
                    }

                    // Offline fallback
                    final cached = _loadProductsFromCache();
                    final products = _applyFilters(cached);

                    _currentProducts = products;

                    if (products.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _maybeSpeakNoProducts(lang);
                      });
                      return Center(child: Text(_t(lang, "no_products")));
                    }

                    return _listBody(products, lang, showOfflineHint: true);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _listBody(
    List<Product> products,
    AppLang lang, {
    required bool showOfflineHint,
  }) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 150),
      itemCount: 1 + products.length + (showOfflineHint ? 1 : 0),
      itemBuilder: (context, index) {
        int i = index;

        if (showOfflineHint) {
          if (i == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7D6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                _t(lang, "offline_cached"),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            );
          }
          i -= 1;
        }

        if (i == 0) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _t(lang, "all_products"),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    "${products.length} ${_t(lang, "products_count")}",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          );
        }

        final p = products[i - 1];
        return _productCard(context, p, lang);
      },
    );
  }

  Widget _productCard(BuildContext context, Product p, AppLang lang) {
    final aiText = p.aiPriceRs <= 0 ? "—" : "Rs ${p.aiPriceRs}";

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
      ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: p.imageUrl,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 170,
                      color: const Color(0xFFE5E7EB),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 170,
                      color: const Color(0xFFE5E7EB),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _categoryChip(_categoryToLabel(lang, p.category)),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _fairDealChip(p.fairDeal, lang),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: "Speak",
                        onPressed: () => _speakProduct(p, lang),
                        icon: const Icon(
                          Icons.volume_up_outlined,
                          color: Color(0xFF2A7BF4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${p.qty} ${p.unit}",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Rs ${p.priceRs}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "✨ ${_t(lang, "ai")}: $aiText",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${_districtToLabel(lang, p.locationName)} • ${p.distanceKm} ${_t(lang, "km")}",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        p.sellerRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String categoryLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        categoryLabel,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFF2A7BF4),
        ),
      ),
    );
  }

  Widget _fairDealChip(bool fair, AppLang lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(
            Icons.thumb_up_alt_outlined,
            size: 16,
            color: fair ? Colors.green : Colors.black45,
          ),
          const SizedBox(width: 6),
          Text(
            fair ? _t(lang, "fair_deal") : _t(lang, "check"),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: fair ? Colors.green : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownBox({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButton<String>(
        value: safeValue,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: items
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => v == null ? null : onChanged(v),
      ),
    );
  }
}

// ✅ Floating buttons widget
class _FloatingButtons extends StatelessWidget {
  final String readLabel;
  final String helpLabel;
  final VoidCallback onStop;
  final VoidCallback onRead;
  final VoidCallback onHelp;

  const _FloatingButtons({
    required this.readLabel,
    required this.helpLabel,
    required this.onStop,
    required this.onRead,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "stop_buy",
          onPressed: onStop,
          backgroundColor: Colors.black87,
          child: const Icon(Icons.stop, color: Colors.white),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: "read_buy",
          onPressed: onRead,
          backgroundColor: const Color(0xFF7C3AED),
          icon: const Icon(Icons.record_voice_over, color: Colors.white),
          label: Text(
            readLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: "help_buy",
          onPressed: onHelp,
          backgroundColor: const Color(0xFF2A7BF4),
          icon: const Icon(Icons.volume_up, color: Colors.white),
          label: Text(
            helpLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

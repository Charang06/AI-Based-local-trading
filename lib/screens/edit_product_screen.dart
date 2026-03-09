import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_language.dart';
import '../services/voice_assistant.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  const EditProductScreen({super.key, required this.productId});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController();

  bool _saving = false;
  bool _loading = true;

  String _unit = "unit";
  String _category = "Food & Vegetables";
  String _locationName = "Colombo";

  File? _newImageFile;

  final List<String> _units = const ["kg", "g", "l", "ml", "unit"];
  final List<String> _categories = const [
    "Food & Vegetables",
    "Electronics",
    "Vehicles",
    "Home & Living",
    "Fashion",
    "Services",
  ];
  static const List<String> _districts = [
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

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection("products").doc(widget.productId);

  String _currentImageUrl = "";

  bool _autoSpoken = false;

  @override
  void initState() {
    super.initState();
    _load();

    // ✅ Auto speak once after UI shows
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _autoSpoken) return;
      _autoSpoken = true;
      final lang = AppLanguage.current.value;
      await _speakEditGuide(lang);
    });
  }

  @override
  void dispose() {
    VoiceAssistant.instance.stop();
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  // =========================
  // ✅ Translations
  // =========================
  String _t(AppLang lang, String key) {
    const en = {
      "title": "Edit Ad",
      "photo": "🖼 Product Photo",
      "take_photo": "Take Photo",
      "upload_photo": "Upload Photo",
      "title_lbl": "✏️ Title",
      "qty_lbl": "📦 Qty",
      "unit_lbl": "Unit",
      "price_lbl": "💰 Price (Rs)",
      "desc_lbl": "📝 Description",
      "category_lbl": "Category",
      "location_lbl": "Location",
      "save": "Save Changes",
      "saving": "Saving...",
      "updated": "Updated ✅",
      "load_failed": "Load failed:",
      "save_failed": "Save failed:",
      "invalid": "Enter valid title, qty and price.",
      "img_need_net":
          "Image upload needs internet. Save text changes only or try online.",
      "help": "Help",
      "stop": "Stop",
      "read": "Read",
    };

    const si = {
      "title": "දැන්වීම සංස්කරණය",
      "photo": "🖼 භාණ්ඩ පින්තූරය",
      "take_photo": "පින්තූර ගන්න",
      "upload_photo": "පින්තූර දාන්න",
      "title_lbl": "✏️ නාමය",
      "qty_lbl": "📦 ප්‍රමාණය",
      "unit_lbl": "ඒකකය",
      "price_lbl": "💰 මිල (රු.)",
      "desc_lbl": "📝 විස්තරය",
      "category_lbl": "වර්ගය",
      "location_lbl": "ස්ථානය",
      "save": "වෙනස්කම් සුරකින්න",
      "saving": "සුරකිනවා...",
      "updated": "යාවත්කාලීන විය ✅",
      "load_failed": "Load අසාර්ථකයි:",
      "save_failed": "Save අසාර්ථකයි:",
      "invalid": "වලංගු නාමය, ප්‍රමාණය සහ මිල දාන්න.",
      "img_need_net":
          "පින්තූර දාන්න Internet අවශ්‍යයි. Text පමණක් Save කරන්න හෝ Online වෙලා නැවත උත්සාහ කරන්න.",
      "help": "උදව්",
      "stop": "නවතන්න",
      "read": "කියවන්න",
    };

    const ta = {
      "title": "விளம்பரம் திருத்து",
      "photo": "🖼 பொருள் படம்",
      "take_photo": "படம் எடு",
      "upload_photo": "படம் பதிவேற்று",
      "title_lbl": "✏️ பெயர்",
      "qty_lbl": "📦 அளவு",
      "unit_lbl": "அலகு",
      "price_lbl": "💰 விலை (ரூ.)",
      "desc_lbl": "📝 விவரம்",
      "category_lbl": "வகை",
      "location_lbl": "இடம்",
      "save": "மாற்றங்களை சேமி",
      "saving": "சேமிக்கிறது...",
      "updated": "புதுப்பிக்கப்பட்டது ✅",
      "load_failed": "Load தோல்வி:",
      "save_failed": "Save தோல்வி:",
      "invalid": "சரியான பெயர், அளவு, விலை உள்ளிடவும்.",
      "img_need_net":
          "படம் பதிவேற்ற Internet தேவை. Text மட்டும் Save செய்யவும் அல்லது Online ஆக முயற்சிக்கவும்.",
      "help": "உதவி",
      "stop": "நிறுத்து",
      "read": "படிக்க",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  // UI-only label for category (keep internal English values)
  String _categoryToLabel(AppLang lang, String internal) {
    if (lang == AppLang.si) {
      switch (internal) {
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
    for (final c in _categories) {
      if (_categoryToLabel(lang, c) == label) return c;
    }
    return _categories.first;
  }

  String _districtToLabel(AppLang lang, String d) {
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
    for (final d in _districts) {
      if (_districtToLabel(lang, d) == label) return d;
    }
    return _districts.first;
  }

  // =========================
  // ✅ Voice
  // =========================
  String _ttsLangCode(AppLang lang) {
    if (lang == AppLang.si) return "si-LK";
    if (lang == AppLang.ta) return "ta-IN";
    return "en-US";
  }

  Future<void> _speakEditGuide(AppLang lang) async {
    final code = _ttsLangCode(lang);

    String text;
    if (lang == AppLang.si) {
      text =
          "මෙය දැන්වීම සංස්කරණ තිරයයි. පින්තූරය වෙනස් කරන්න, නාමය, ප්‍රමාණය, ඒකකය, මිල, විස්තරය, වර්ගය සහ ස්ථානය සකස් කරන්න. අවසානයේ ‘වෙනස්කම් සුරකින්න’ ඔබන්න. Stop මගින් කථනය නවතන්න. Read මගින් සාරාංශය අහන්න.";
    } else if (lang == AppLang.ta) {
      text =
          "இது விளம்பரம் திருத்தும் திரை. படம் மாற்றவும், பெயர், அளவு, அலகு, விலை, விவரம், வகை மற்றும் இடத்தை மாற்றவும். முடிவில் ‘மாற்றங்களை சேமி’ அழுத்தவும். Stop மூலம் பேசுவதை நிறுத்தலாம். Read மூலம் சுருக்கம் கேட்கலாம்.";
    } else {
      text =
          "This is the Edit Ad screen. Change photo, title, quantity, unit, price, description, category and location. Finally tap Save Changes. Use Stop to cancel speaking. Use Read to hear a short summary.";
    }

    await VoiceAssistant.instance.init(languageCode: code);
    await VoiceAssistant.instance.speak(text);
  }

  Future<void> _speakSummary(AppLang lang) async {
    final code = _ttsLangCode(lang);

    final title = _title.text.trim();
    final qty = _qty.text.trim();
    final unit = _unit;
    final price = _price.text.trim();
    final cat = _category;
    final loc = _locationName;

    String text;
    if (lang == AppLang.si) {
      text =
          "සාරාංශය. නාමය: $title. ප්‍රමාණය: $qty $unit. මිල: රුපියල් $price. වර්ගය: ${_categoryToLabel(lang, cat)}. ස්ථානය: ${_districtToLabel(lang, loc)}.";
    } else if (lang == AppLang.ta) {
      text =
          "சுருக்கம். பெயர்: $title. அளவு: $qty $unit. விலை: ரூபாய் $price. வகை: ${_categoryToLabel(lang, cat)}. இடம்: ${_districtToLabel(lang, loc)}.";
    } else {
      text =
          "Summary. Title: $title. Quantity: $qty $unit. Price: rupees $price. Category: $cat. Location: $loc.";
    }

    await VoiceAssistant.instance.init(languageCode: code);
    await VoiceAssistant.instance.speak(text);
  }

  // =========================
  // ✅ Data load/save
  // =========================
  Future<void> _load() async {
    try {
      final snap = await _ref.get();
      final d = snap.data() ?? {};

      _title.text = (d["title"] ?? "").toString();
      _desc.text = (d["description"] ?? "").toString();
      _price.text = ((d["priceRs"] as num?)?.toInt() ?? 0).toString();
      _qty.text = ((d["qty"] as num?)?.toDouble() ?? 1).toString();

      _currentImageUrl = (d["imageUrl"] ?? "").toString();

      final unit = (d["unit"] ?? "unit").toString();
      final cat = (d["category"] ?? "Food & Vegetables").toString();
      final loc = (d["locationName"] ?? "Colombo").toString();

      if (!mounted) return;
      setState(() {
        _unit = _units.contains(unit) ? unit : "unit";
        _category = _categories.contains(cat) ? cat : "Food & Vegetables";
        _locationName = _districts.contains(loc) ? loc : "Colombo";
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Load failed: $e")));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source, imageQuality: 80);
    if (x == null) return;
    setState(() => _newImageFile = File(x.path));
  }

  Future<String> _uploadNewImage(File file) async {
    final path =
        "products/edited/${widget.productId}_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> _save(AppLang lang) async {
    final title = _title.text.trim();
    final desc = _desc.text.trim();
    final priceRs = int.tryParse(_price.text.trim()) ?? 0;
    final qty = double.tryParse(_qty.text.trim()) ?? 0;

    if (title.isEmpty || priceRs <= 0 || qty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "invalid"))));
      return;
    }

    setState(() => _saving = true);
    try {
      String imageUrl = _currentImageUrl;

      if (_newImageFile != null) {
        try {
          imageUrl = await _uploadNewImage(_newImageFile!);
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_t(lang, "img_need_net"))));
          imageUrl = _currentImageUrl;
        }
      }

      await _ref.update({
        "title": title,
        "description": desc,
        "priceRs": priceRs,
        "qty": qty,
        "unit": _unit,
        "category": _category,
        "locationName": _locationName,
        "imageUrl": imageUrl,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "updated"))));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${_t(lang, "save_failed")} $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // =========================
  // ✅ UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_t(lang, "title")),
            backgroundColor: const Color(0xFF2A7BF4),
            actions: [
              IconButton(
                tooltip: _t(lang, "stop"),
                onPressed: () => VoiceAssistant.instance.stop(),
                icon: const Icon(Icons.stop),
              ),
              IconButton(
                tooltip: _t(lang, "read"),
                onPressed: () => _speakSummary(lang),
                icon: const Icon(Icons.record_voice_over),
              ),
              IconButton(
                tooltip: _t(lang, "help"),
                onPressed: () => _speakEditGuide(lang),
                icon: const Icon(Icons.volume_up),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t(lang, "photo"),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _photoBtn(
                              icon: Icons.camera_alt_outlined,
                              label: _t(lang, "take_photo"),
                              onTap: () => _pickImage(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _photoBtn(
                              icon: Icons.upload_outlined,
                              label: _t(lang, "upload_photo"),
                              onTap: () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _newImageFile != null
                            ? Image.file(
                                _newImageFile!,
                                height: 170,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : (_currentImageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: _currentImageUrl,
                                      height: 170,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        height: 170,
                                        color: const Color(0xFFE5E7EB),
                                        alignment: Alignment.center,
                                        child:
                                            const CircularProgressIndicator(),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        height: 170,
                                        color: const Color(0xFFE5E7EB),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.image_not_supported_outlined,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      height: 170,
                                      color: const Color(0xFFE5E7EB),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                      ),
                                    )),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        _t(lang, "title_lbl"),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _title,
                        decoration: _inputDeco("e.g. Banana"),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t(lang, "qty_lbl"),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _qty,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _inputDeco("1"),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dropdown(
                              _t(lang, "unit_lbl"),
                              _unit,
                              _units,
                              (v) => setState(() => _unit = v),
                              display: (v) => v,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Text(
                        _t(lang, "price_lbl"),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco("150"),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        _t(lang, "desc_lbl"),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _desc,
                        maxLines: 4,
                        decoration: _inputDeco("Write details..."),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _dropdown(
                              _t(lang, "category_lbl"),
                              _categoryToLabel(lang, _category),
                              _categories
                                  .map((c) => _categoryToLabel(lang, c))
                                  .toList(),
                              (label) => setState(() {
                                _category = _labelToCategory(lang, label);
                              }),
                              display: (v) => v,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dropdown(
                              _t(lang, "location_lbl"),
                              _districtToLabel(lang, _locationName),
                              _districts
                                  .map((d) => _districtToLabel(lang, d))
                                  .toList(),
                              (label) => setState(() {
                                _locationName = _labelToDistrict(lang, label);
                              }),
                              display: (v) => v,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : () => _save(lang),
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            _saving ? _t(lang, "saving") : _t(lang, "save"),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _photoBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          color: Colors.white,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black54),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged, {
    required String Function(String) display,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            value: safeValue,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(display(e))))
                .toList(),
            onChanged: (v) => v == null ? null : onChanged(v),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}

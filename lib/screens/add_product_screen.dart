import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../app_language.dart';
import '../services/ai_pricing.dart';
import '../services/voice_assistant.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController(text: "1");

  bool _posting = false;
  bool _aiLoading = false;
  File? _imageFile;

  // Category
  String _category = "Food & Vegetables";
  final List<String> _categories = const [
    "Food & Vegetables",
    "Electronics",
    "Vehicles",
    "Home & Living",
    "Fashion",
    "Services",
  ];

  // Sri Lanka Districts
  String _locationName = "Colombo";
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

  // Qty + Unit
  String _unit = "kg";
  final List<String> _units = const ["kg", "g", "l", "ml", "unit"];

  // ✅ AI values
  int _aiPrice = 0;
  int _marketLow = 0;
  int _marketHigh = 0;
  int _aiReqId = 0; // prevents stale response

  // ✅ NEW (from suggestSmart)
  AiConfidence _aiConfidence = AiConfidence.none;
  int _aiSampleCount = 0;
  String _aiSource = "";
  String _aiExplanation = "";

  // ✅ Voice input (STT)
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _listeningTitle = false;
  bool _listeningDesc = false;
  bool _listeningPrice = false;

  // ✅ Auto speak once
  bool _autoSpoken = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _autoSpoken) return;
      _autoSpoken = true;

      final lang = AppLanguage.current.value;
      await _speakSellGuide(lang);
    });
  }

  @override
  void dispose() {
    _stt.stop();
    VoiceAssistant.instance.stop();

    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  // =========================
  // ✅ Voice Guide (EN / SI / TA)
  // =========================
  Future<void> _speakSellGuide(AppLang lang) async {
    String langCode;
    String text;

    if (lang == AppLang.si) {
      langCode = "si-LK";
      text =
          "මෙය භාණ්ඩ එකතු කරන තිරයයි. පළමුව පින්තූරයක් ගන්න හෝ අප්ලෝඩ් කරන්න. ඉන්පසු භාණ්ඩ නාමය ලියන්න හෝ මයික් එකෙන් කියන්න. ප්‍රමාණය සහ ඒකකය තෝරන්න. මිල ඇතුළත් කරන්න. අවසානයේ පෝස්ට් බොත්තම ඔබන්න.";
    } else if (lang == AppLang.ta) {
      langCode = "ta-IN";
      text =
          "இது பொருள் சேர்க்கும் திரை. முதலில் படம் எடுக்கவும் அல்லது பதிவேற்றவும். பிறகு பொருள் பெயரை எழுதவும் அல்லது மைகில் பேசவும். அளவு மற்றும் அலகை தேர்வு செய்யவும். விலையை உள்ளிடவும். கடைசியில் பதிவிடு பொத்தானை அழுத்தவும்.";
    } else {
      langCode = "en-US";
      text =
          "This is the Sell screen. First, take or upload a photo. Then type the product name or use the mic. Choose quantity and unit. Enter your price. Finally, tap Post Product.";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  // =========================
  // ✅ STT helpers
  // =========================
  String _sttLocaleId(AppLang lang) {
    if (lang == AppLang.si) return "si_LK";
    if (lang == AppLang.ta) return "ta_IN";
    return "en_US";
  }

  Future<void> _stopListeningUi() async {
    if (_stt.isListening) {
      await _stt.stop();
    }
    if (!mounted) return;
    setState(() {
      _listeningTitle = false;
      _listeningDesc = false;
      _listeningPrice = false;
    });
  }

  Future<void> _toggleVoiceForController({
    required TextEditingController controller,
    required AppLang lang,
    required bool isTitle,
  }) async {
    if (_stt.isListening) {
      await _stopListeningUi();
      return;
    }

    final ok = await _stt.initialize(onStatus: (_) {}, onError: (_) {});
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Voice input not available on this device."),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _listeningTitle = isTitle;
      _listeningDesc = !isTitle;
      _listeningPrice = false;
    });

    await _stt.listen(
      localeId: _sttLocaleId(lang),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
      onResult: (res) {
        if (!mounted) return;

        controller.text = res.recognizedWords;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );

        if (isTitle && res.finalResult) {
          _refreshAiPrice(); // no await
        }

        if (res.finalResult) {
          setState(() {
            _listeningTitle = false;
            _listeningDesc = false;
          });
        }
      },
    );
  }

  double? _extractNumber(String speech) {
    final s = speech.replaceAll(',', '').trim();
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(s);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  Future<void> _toggleVoiceForPrice({required AppLang lang}) async {
    if (_stt.isListening) {
      await _stopListeningUi();
      return;
    }

    final ok = await _stt.initialize(onStatus: (_) {}, onError: (_) {});
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Voice input not available on this device."),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _listeningTitle = false;
      _listeningDesc = false;
      _listeningPrice = true;
    });

    await _stt.listen(
      localeId: _sttLocaleId(lang),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
      onResult: (res) {
        if (!mounted) return;

        final spoken = res.recognizedWords;
        final num = _extractNumber(spoken);

        if (num != null) {
          final rs = num.round();
          _price.text = rs.toString();
          _price.selection = TextSelection.fromPosition(
            TextPosition(offset: _price.text.length),
          );
        }

        if (res.finalResult) {
          setState(() => _listeningPrice = false);

          if (num == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Couldn’t detect a number. Try again like: 150"),
              ),
            );
            return;
          }
          _refreshAiPrice();
        }
      },
    );
  }

  void _applyAiPriceToInput() {
    if (_aiPrice <= 0) return;
    setState(() => _price.text = _aiPrice.toString());
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("AI price applied ✅")));
  }

  double _readQty() {
    final v = double.tryParse(_qty.text.trim());
    if (v == null || v <= 0) return 0;
    return v;
  }

  bool _calcFairDeal(int price) {
    if (_marketLow == 0 || _marketHigh == 0) return false;
    return price >= _marketLow && price <= _marketHigh;
  }

  void _resetAiUi() {
    setState(() {
      _aiPrice = 0;
      _marketLow = 0;
      _marketHigh = 0;
      _aiConfidence = AiConfidence.none;
      _aiSampleCount = 0;
      _aiSource = "";
      _aiExplanation = "";
    });
  }

  // =========================
  // ✅ AI price refresh (FIXED)
  // =========================
  Future<void> _refreshAiPrice() async {
    final t = _title.text.trim();
    final qty = _readQty();

    if (t.isEmpty || qty <= 0) {
      if (!mounted) return;
      _resetAiUi();
      return;
    }

    final userPrice = int.tryParse(_price.text.trim()) ?? 0;

    final myReq = ++_aiReqId;
    setState(() => _aiLoading = true);

    try {
      // ✅ FIX: use suggestSmart (category + location)
      final res = await AiPricingService.suggestSmart(
        title: t,
        category: _category,
        locationName: _locationName,
        userQty: qty,
        userUnit: _unit,
        userPriceRs: userPrice,
      );

      if (!mounted || myReq != _aiReqId) return;

      setState(() {
        _aiPrice = res.suggestedPrice;
        _marketLow = res.marketLow;
        _marketHigh = res.marketHigh;

        _aiConfidence = res.confidence;
        _aiSampleCount = res.sampleCount;
        _aiSource = res.source;
        _aiExplanation = res.explanation;
      });
    } catch (_) {
      // ignore AI errors
    } finally {
      if (mounted && myReq == _aiReqId) setState(() => _aiLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source, imageQuality: 80);
    if (x == null) return;
    setState(() => _imageFile = File(x.path));
  }

  Future<String> _uploadImageToStorage(File file) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("Not logged in");

    final path = "products/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref = FirebaseStorage.instance.ref().child(path);

    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> _postProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login first.")));
      return;
    }

    final title = _title.text.trim();
    final description = _desc.text.trim();
    final priceRs = int.tryParse(_price.text.trim()) ?? 0;
    final qty = _readQty();

    if (title.isEmpty || qty <= 0 || priceRs <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter product name, qty and valid price."),
        ),
      );
      return;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a product photo.")),
      );
      return;
    }

    await _refreshAiPrice();

    if (!mounted) return;
    setState(() => _posting = true);

    try {
      final imageUrl = await _uploadImageToStorage(_imageFile!);
      final normalizedTitle = AiPricingService.normalizeTitle(title);

      final base = AiPricingService.toBase(qty, _unit);
      final ppb = (base.baseQty <= 0) ? 0.0 : (priceRs / base.baseQty);

      final fairDeal = _calcFairDeal(priceRs);

      await FirebaseFirestore.instance.collection("products").add({
        "title": title,
        "normalizedTitle": normalizedTitle,
        "description": description,
        "imageUrl": imageUrl,
        "priceRs": priceRs,
        "qty": qty,
        "unit": _unit,
        "baseQty": base.baseQty,
        "baseUnit": base.baseUnit,
        "pricePerBase": ppb,
        "aiPriceRs": _aiPrice,
        "fairDeal": fairDeal,
        "marketLow": _marketLow,
        "marketHigh": _marketHigh,
        "sellerId": user.uid,
        "sellerPhone": user.phoneNumber ?? "",
        "sellerName": "Seller",
        "sellerRating": 4.5,
        "locationName": _locationName,
        "lat": 0.0,
        "lng": 0.0,
        "distanceKm": 0.0,
        "category": _category,
        "tags": ["Fresh"],
        "status": "active",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product posted successfully ✅")),
      );

      _title.clear();
      _desc.clear();
      _price.clear();
      _qty.text = "1";

      setState(() {
        _imageFile = null;
        _aiPrice = 0;
        _marketLow = 0;
        _marketHigh = 0;
        _aiConfidence = AiConfidence.none;
        _aiSampleCount = 0;
        _aiSource = "";
        _aiExplanation = "";
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Post failed: $e")));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  String _confidenceText(AiConfidence c) {
    switch (c) {
      case AiConfidence.high:
        return "High";
      case AiConfidence.medium:
        return "Medium";
      case AiConfidence.low:
        return "Low";
      case AiConfidence.none:
        return "None";
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAiSuggestion = _aiPrice > 0;

    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Add Product"),
            backgroundColor: const Color(0xFF22C55E),
            actions: [
              IconButton(
                tooltip: "Stop voice",
                onPressed: () => VoiceAssistant.instance.stop(),
                icon: const Icon(Icons.stop_circle_outlined),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: "stop_speak_sell",
                onPressed: () => VoiceAssistant.instance.stop(),
                backgroundColor: Colors.black87,
                child: const Icon(Icons.stop, color: Colors.white),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: "help_speak_sell",
                onPressed: () => _speakSellGuide(lang),
                backgroundColor: const Color(0xFF2A7BF4),
                icon: const Icon(Icons.volume_up, color: Colors.white),
                label: const Text(
                  "Help",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "🖼 Product Photo",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _photoButton(
                        icon: Icons.camera_alt_outlined,
                        label: "Take Photo",
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _photoButton(
                        icon: Icons.upload_outlined,
                        label: "Upload Photo",
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                if (_imageFile != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _imageFile!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown("Category", _category, _categories, (
                        v,
                      ) async {
                        setState(() => _category = v);
                        await _refreshAiPrice();
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdown("Location", _locationName, _districts, (
                        v,
                      ) async {
                        setState(() => _locationName = v);
                        await _refreshAiPrice();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  "✏️ Product Name",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _title,
                  onChanged: (_) => _refreshAiPrice(),
                  decoration: _inputDeco("e.g., Banana / Vitz / iPhone")
                      .copyWith(
                        suffixIcon: IconButton(
                          tooltip: "Voice input",
                          onPressed: () => _toggleVoiceForController(
                            controller: _title,
                            lang: lang,
                            isTitle: true,
                          ),
                          icon: Icon(
                            _listeningTitle ? Icons.mic : Icons.mic_none,
                            color: _listeningTitle
                                ? const Color(0xFF2A7BF4)
                                : Colors.black54,
                          ),
                        ),
                      ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "📦 Quantity",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _qty,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => _refreshAiPrice(),
                            decoration: _inputDeco("1"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdown("Unit", _unit, _units, (v) async {
                        setState(() => _unit = v);
                        await _refreshAiPrice();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  "📝 Describe",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _desc,
                  maxLines: 4,
                  decoration: _inputDeco("Write product details...").copyWith(
                    suffixIcon: IconButton(
                      tooltip: "Voice input",
                      onPressed: () => _toggleVoiceForController(
                        controller: _desc,
                        lang: lang,
                        isTitle: false,
                      ),
                      icon: Icon(
                        _listeningDesc ? Icons.mic : Icons.mic_none,
                        color: _listeningDesc
                            ? const Color(0xFF2A7BF4)
                            : Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ✅ AI Box (updated)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7EFFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "✨ AI Suggested Price",
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (hasAiSuggestion)
                            TextButton.icon(
                              onPressed: _applyAiPriceToInput,
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                              label: const Text("Use"),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF7C3AED),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            hasAiSuggestion ? "Rs $_aiPrice" : "—",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (_aiLoading)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (_marketLow == 0 || _marketHigh == 0)
                            ? "AI needs SOLD history (product/category) to suggest a price."
                            : "Market range: Rs $_marketLow - Rs $_marketHigh",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      if (_aiExplanation.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          "$_aiExplanation  (Confidence: ${_confidenceText(_aiConfidence)})",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const Text(
                  "💰 Your Price",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _refreshAiPrice(),
                  decoration: _inputDeco("Rs 150").copyWith(
                    suffixIcon: IconButton(
                      tooltip: "Voice price",
                      onPressed: () => _toggleVoiceForPrice(lang: lang),
                      icon: Icon(
                        _listeningPrice ? Icons.mic : Icons.mic_none,
                        color: _listeningPrice
                            ? const Color(0xFF2A7BF4)
                            : Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _posting ? null : _postProduct,
                    icon: _posting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      _posting ? "Posting..." : "Post Product",
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

  Widget _photoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 92,
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
    ValueChanged<String> onChanged,
  ) {
    final safeValue = items.contains(value) ? value : items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
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
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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

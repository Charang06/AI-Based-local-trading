import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ai_pricing.dart';

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

  int _aiPrice = 0;
  int _marketLow = 0;
  int _marketHigh = 0;

  int _aiReqId = 0; // prevents stale response (banana -> carrot bug)

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  // ✅ apply AI price into the price textbox (button action)
  void _applyAiPriceToInput() {
    if (_aiPrice <= 0) return;
    setState(() {
      _price.text = _aiPrice.toString();
    });
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
    });
  }

  Future<void> _refreshAiPrice() async {
    final t = _title.text.trim();
    final qty = _readQty();

    // ✅ IMPORTANT: Only sold-data. If missing title/qty -> show empty.
    if (t.isEmpty || qty <= 0) {
      if (!mounted) return;
      _resetAiUi();
      return;
    }

    // userPrice is ONLY for fairDeal check inside AiPricingService (optional)
    final userPrice = int.tryParse(_price.text.trim()) ?? 0;

    final myReq = ++_aiReqId;
    setState(() => _aiLoading = true);

    try {
      final res = await AiPricingService.suggestFromHistory(
        title: t,
        locationName: _locationName,
        userQty: qty,
        userUnit: _unit,
        userPriceRs: userPrice,
      );

      if (!mounted || myReq != _aiReqId) return;

      setState(() {
        // ✅ only sold-data => if none, they remain 0 and UI shows "—"
        _aiPrice = res.suggestedPrice;
        _marketLow = res.marketLow;
        _marketHigh = res.marketHigh;

        // ❌ Do not auto-copy user price
        // ❌ Do not auto-fill price field
        // user must press "Use" button if they want to apply
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

    // refresh AI once (only sold-data, no auto-copy)
    await _refreshAiPrice();

    setState(() => _posting = true);

    try {
      final imageUrl = await _uploadImageToStorage(_imageFile!);

      final normalizedTitle = AiPricingService.normalizeTitle(title);

      // base conversion + ppb
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

        // ✅ store AI snapshot (0 if no sold history)
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

  @override
  Widget build(BuildContext context) {
    final hasAiSuggestion = _aiPrice > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Product"),
        backgroundColor: const Color(0xFF22C55E),
      ),
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

            // Category + Location
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
              decoration: _inputDeco("e.g., Banana / Vitz / iPhone"),
            ),

            const SizedBox(height: 14),

            // Qty + Unit
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
              decoration: _inputDeco("Write product details..."),
            ),

            const SizedBox(height: 14),

            // AI Suggested Price (with Use button)
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
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
                        ? "AI needs SOLD history for this product + location"
                        : "Market range: Rs $_marketLow - Rs $_marketHigh",
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
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
              decoration: _inputDeco("Rs 150"),
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

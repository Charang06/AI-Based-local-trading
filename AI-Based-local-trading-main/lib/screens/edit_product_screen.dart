import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  File? _newImageFile; // ✅ NEW (picked image)

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

  String _currentImageUrl = ""; // ✅ existing image url

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

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

  Future<void> _save() async {
    final title = _title.text.trim();
    final desc = _desc.text.trim();
    final priceRs = int.tryParse(_price.text.trim()) ?? 0;
    final qty = double.tryParse(_qty.text.trim()) ?? 0;

    if (title.isEmpty || priceRs <= 0 || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid title, qty and price.")),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      String imageUrl = _currentImageUrl;

      // ✅ if user picked a new image, upload it
      if (_newImageFile != null) {
        imageUrl = await _uploadNewImage(_newImageFile!);
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
        "updatedAt":
            FieldValue.serverTimestamp(), // ✅ make sure rules allow this
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Updated ✅")));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Ad"),
        backgroundColor: const Color(0xFF2A7BF4),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        child: _photoBtn(
                          icon: Icons.camera_alt_outlined,
                          label: "Take Photo",
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _photoBtn(
                          icon: Icons.upload_outlined,
                          label: "Upload Photo",
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
                              ? Image.network(
                                  _currentImageUrl,
                                  height: 170,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
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
                  const Text(
                    "✏️ Title",
                    style: TextStyle(fontWeight: FontWeight.w900),
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
                            const Text(
                              "📦 Qty",
                              style: TextStyle(fontWeight: FontWeight.w900),
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
                          "Unit",
                          _unit,
                          _units,
                          (v) => setState(() => _unit = v),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    "💰 Price (Rs)",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco("150"),
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    "📝 Description",
                    style: TextStyle(fontWeight: FontWeight.w900),
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
                          "Category",
                          _category,
                          _categories,
                          (v) => setState(() => _category = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dropdown(
                          "Location",
                          _locationName,
                          _districts,
                          (v) => setState(() => _locationName = v),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        _saving ? "Saving..." : "Save Changes",
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
    ValueChanged<String> onChanged,
  ) {
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_language.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class BuyProductsScreen extends StatefulWidget {
  const BuyProductsScreen({super.key});

  @override
  State<BuyProductsScreen> createState() => _BuyProductsScreenState();
}

class _BuyProductsScreenState extends State<BuyProductsScreen> {
  final TextEditingController _search = TextEditingController();

  bool fairDealOnly = false;
  double maxDistanceKm = 10;
  int minPrice = 0;
  int maxPrice = 1000000;

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

  double minSellerRating = 0;
  String selectedLocation = "All";

  // ✅ Full Sri Lanka Districts list (for filter dropdown)
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  DateTime? _tsToDate(dynamic v) => v is Timestamp ? v.toDate() : null;

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
    };

    final map = (lang == AppLang.si) ? en : (lang == AppLang.ta ? en : en);
    return map[key] ?? key;
  }

  String _categoryToLabel(AppLang lang, String internal) =>
      internal == "All" ? _t(lang, "all") : internal;
  String _labelToCategory(AppLang lang, String label) =>
      label == _t(lang, "all") ? "All" : label;
  String _locationToLabel(AppLang lang, String internal) =>
      internal == "All" ? _t(lang, "all") : internal;
  String _labelToLocation(AppLang lang, String label) =>
      label == _t(lang, "all") ? "All" : label;

  Product _fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return Product(
      id: doc.id,
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

  void _openFilter(AppLang lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) {
          final categoryItems = categories
              .map((c) => _categoryToLabel(lang, c))
              .toList();

          final locationItems = <String>[_t(lang, "all"), ...districts];

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

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _t(lang, "filters"),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

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
                  value: _locationToLabel(lang, selectedLocation),
                  items: locationItems,
                  onChanged: (label) => setSheet(() {
                    selectedLocation = _labelToLocation(lang, label);
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
        return Scaffold(
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _t(lang, "search"),
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                        ),
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
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text("Error: ${snap.error}"));
                    }

                    final docs = snap.data?.docs ?? [];
                    final allProducts = docs.map(_fromDoc).toList();
                    final products = _applyFilters(allProducts);

                    if (products.isEmpty) {
                      return Center(child: Text(_t(lang, "no_products")));
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                        ...products.map((p) => _productCard(context, p, lang)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
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
                  Image.network(
                    p.imageUrl,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 170,
                      color: const Color(0xFFE5E7EB),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _categoryChip(p.category),
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
                  Text(
                    p.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),

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
                          "${p.locationName} • ${p.distanceKm} ${_t(lang, "km")}",
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

  Widget _categoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category,
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

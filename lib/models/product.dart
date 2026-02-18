class Product {
  final String id;
  final String title;
  final String imageUrl;

  // user entered
  final int priceRs;

  // qty/unit (NEW but optional for old data)
  final double qty;
  final String unit;

  // normalized/base fields (NEW but optional for old data)
  final double baseQty;
  final String baseUnit;
  final double pricePerBase;

  // AI
  final int aiPriceRs;
  final bool fairDeal;
  final int marketLow;
  final int marketHigh;

  // seller
  final String sellerId; // NEW
  final String sellerName;
  final String sellerPhone;
  final double sellerRating;

  // location
  final double distanceKm;
  final String locationName;
  final double lat;
  final double lng;

  // misc
  final String description;
  final List<String> tags;
  final String category;

  // lifecycle
  final String status; // "active" / "sold"
  final DateTime? createdAt;
  final DateTime? soldAt;

  const Product({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.priceRs,

    // ✅ defaults for old products
    this.qty = 1.0,
    this.unit = "pcs",
    this.baseQty = 1.0,
    this.baseUnit = "pcs",
    this.pricePerBase = 0.0,

    this.aiPriceRs = 0,
    this.fairDeal = false,
    this.marketLow = 0,
    this.marketHigh = 0,

    // ✅ sellerId default for old data (but you should store it when posting)
    this.sellerId = "",
    this.sellerName = "",
    this.sellerPhone = "",
    this.sellerRating = 0,

    this.distanceKm = 0,
    this.locationName = "Unknown",
    this.lat = 0,
    this.lng = 0,

    this.description = "",
    this.tags = const [],
    this.category = "Other",

    this.status = "active",
    this.createdAt,
    this.soldAt,
  });

  Product copyWith({
    String? id,
    String? title,
    String? imageUrl,
    int? priceRs,
    double? qty,
    String? unit,
    double? baseQty,
    String? baseUnit,
    double? pricePerBase,
    int? aiPriceRs,
    bool? fairDeal,
    int? marketLow,
    int? marketHigh,
    String? sellerId,
    String? sellerName,
    String? sellerPhone,
    double? sellerRating,
    double? distanceKm,
    String? locationName,
    double? lat,
    double? lng,
    String? description,
    List<String>? tags,
    String? category,
    String? status,
    DateTime? createdAt,
    DateTime? soldAt,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      priceRs: priceRs ?? this.priceRs,

      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      baseQty: baseQty ?? this.baseQty,
      baseUnit: baseUnit ?? this.baseUnit,
      pricePerBase: pricePerBase ?? this.pricePerBase,

      aiPriceRs: aiPriceRs ?? this.aiPriceRs,
      fairDeal: fairDeal ?? this.fairDeal,
      marketLow: marketLow ?? this.marketLow,
      marketHigh: marketHigh ?? this.marketHigh,

      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerRating: sellerRating ?? this.sellerRating,

      distanceKm: distanceKm ?? this.distanceKm,
      locationName: locationName ?? this.locationName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,

      description: description ?? this.description,
      tags: tags ?? this.tags,
      category: category ?? this.category,

      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      soldAt: soldAt ?? this.soldAt,
    );
  }
}

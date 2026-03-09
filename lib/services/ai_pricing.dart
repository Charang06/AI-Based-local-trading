// lib/services/ai_pricing.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum AiConfidence { none, low, medium, high }

class AiPriceResult {
  final int suggestedPrice;
  final int marketLow;
  final int marketHigh;
  final bool fairDeal;

  final double suggestedPricePerBase;
  final String baseUnit;

  final AiConfidence confidence;
  final int sampleCount;
  final String source; // exact / category_location / category / none
  final String explanation;

  const AiPriceResult({
    required this.suggestedPrice,
    required this.marketLow,
    required this.marketHigh,
    required this.fairDeal,
    required this.suggestedPricePerBase,
    required this.baseUnit,
    required this.confidence,
    required this.sampleCount,
    required this.source,
    required this.explanation,
  });

  bool get hasSuggestion =>
      suggestedPrice > 0 && marketLow > 0 && marketHigh > 0;
}

class UnitConv {
  final double baseQty;
  final String baseUnit;
  const UnitConv(this.baseQty, this.baseUnit);
}

class AiPricingService {
  // -------------------------
  // ✅ Normalize title for matching
  // -------------------------
  static String normalizeTitle(String title) {
    var t = title.toLowerCase().trim();

    // keep only a-z 0-9 spaces
    t = t.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');

    // remove qty patterns inside title like "1kg", "500 g", "2l", "250ml", "3pcs"
    t = t.replaceAll(
      RegExp(
        r'\b\d+(\.\d+)?\s*(kg|g|gram|grams|l|ml|pcs|pc|piece|pieces|unit)\b',
      ),
      ' ',
    );

    // remove leftover standalone numbers
    t = t.replaceAll(RegExp(r'\b\d+\b'), ' ');

    // collapse spaces
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();

    return t;
  }

  // -------------------------
  // ✅ Unit conversions to base
  // Base units:
  // - weight -> kg
  // - volume -> l
  // - count  -> unit
  // -------------------------
  static UnitConv toBase(double qty, String unitRaw) {
    final unit = unitRaw.toLowerCase().trim();
    if (qty <= 0) return const UnitConv(0, "unit");

    // Weight
    if (unit == "kg") return UnitConv(qty, "kg");
    if (unit == "g" || unit == "gram" || unit == "grams") {
      return UnitConv(qty / 1000.0, "kg");
    }

    // Volume
    if (unit == "l") return UnitConv(qty, "l");
    if (unit == "ml") return UnitConv(qty / 1000.0, "l");

    // Count
    if (unit == "pcs" ||
        unit == "pc" ||
        unit == "piece" ||
        unit == "pieces" ||
        unit == "unit") {
      return UnitConv(qty, "unit");
    }

    // fallback
    return UnitConv(qty, unit);
  }

  static double pricePerBase({
    required int priceRs,
    required double qty,
    required String unit,
  }) {
    final b = toBase(qty, unit);
    if (b.baseQty <= 0) return 0;
    return priceRs / b.baseQty;
  }

  // -------------------------
  // ✅ Confidence calculator
  // -------------------------
  static AiConfidence _confidence(int n) {
    if (n >= 15) return AiConfidence.high;
    if (n >= 7) return AiConfidence.medium;
    if (n >= 3) return AiConfidence.low;
    return AiConfidence.none;
  }

  // -------------------------
  // ✅ Fetch SOLD price-per-base pairs
  // returns list of {"ppb": <pricePerBase>, "w": <weight>}
  // Weight is based on recency: newer sold items = higher weight
  // -------------------------
  static Future<List<Map<String, double>>> _fetchPairs({
    String? normalizedTitle,
    String? category,
    String? location,
    int limit = 40,
  }) async {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection("products")
        .where("status", isEqualTo: "sold");

    if (normalizedTitle != null && normalizedTitle.isNotEmpty) {
      q = q.where("normalizedTitle", isEqualTo: normalizedTitle);
    }

    if (category != null && category.isNotEmpty && category != "All") {
      q = q.where("category", isEqualTo: category);
    }

    if (location != null && location.isNotEmpty && location != "All") {
      q = q.where("locationName", isEqualTo: location);
    }

    // NOTE: This query may require a Firestore composite index depending on your data.
    final snap = await q.orderBy("soldAt", descending: true).limit(limit).get();

    final result = <Map<String, double>>[];

    for (final doc in snap.docs) {
      final d = doc.data();

      double ppb = (d["pricePerBase"] as num?)?.toDouble() ?? 0;

      // fallback compute if missing
      if (ppb <= 0) {
        final price = (d["priceRs"] as num?)?.toInt() ?? 0;
        final qty = (d["qty"] as num?)?.toDouble() ?? 0;
        final unit = (d["unit"] ?? "").toString();

        if (price > 0 && qty > 0 && unit.isNotEmpty) {
          ppb = pricePerBase(priceRs: price, qty: qty, unit: unit);
        }
      }

      if (ppb <= 0) continue;

      // ✅ recency weight: today=1, 10 days=1/11, 60 days=1/61
      double weight = 1.0;
      final soldAt = d["soldAt"];
      if (soldAt is Timestamp) {
        final days = DateTime.now().difference(soldAt.toDate()).inDays;
        final dd = days < 0 ? 0 : (days > 60 ? 60 : days);
        weight = 1.0 / (1.0 + dd);
      }

      result.add({"ppb": ppb, "w": weight});
    }

    return result;
  }

  // -------------------------
  // ✅ Weighted median
  // -------------------------
  static double _median(List<Map<String, double>> pairs) {
    pairs.sort((a, b) => a["ppb"]!.compareTo(b["ppb"]!));

    final totalW = pairs.fold<double>(0.0, (s, e) => s + e["w"]!);

    double cum = 0.0;
    double median = pairs.first["ppb"]!;

    for (final p in pairs) {
      cum += p["w"]!;
      if (cum >= totalW / 2.0) {
        median = p["ppb"]!;
        break;
      }
    }

    return median;
  }

  // --------------------------------------------------------------------------
  // ✅ BACKWARD COMPATIBILITY (Fixes your error)
  // Your AddProductScreen calls: AiPricingService.suggestFromHistory(...)
  // So we keep it here, and internally use suggestSmart.
  // --------------------------------------------------------------------------
  static Future<AiPriceResult> suggestFromHistory({
    required String title,
    required String locationName,
    required double userQty,
    required String userUnit,
    required int userPriceRs,
    int limit = 40,
  }) async {
    // Use "exact product + location" (no category fallback) OR use full suggestSmart.
    // Here we use suggestSmart but with category="All" so fallback doesn't filter badly.
    return suggestSmart(
      title: title,
      category: "All",
      locationName: locationName,
      userQty: userQty,
      userUnit: userUnit,
      userPriceRs: userPriceRs,
      limit: limit,
    );
  }

  // --------------------------------------------------------------------------
  // ✅ SMART AI suggestion (with fallback)
  // 1) normalizedTitle + location
  // 2) category + location
  // 3) category only
  // --------------------------------------------------------------------------
  static Future<AiPriceResult> suggestSmart({
    required String title,
    required String category,
    required String locationName,
    required double userQty,
    required String userUnit,
    required int userPriceRs,
    int limit = 40,
  }) async {
    final norm = normalizeTitle(title);
    final base = toBase(userQty, userUnit);

    if (base.baseQty <= 0) {
      return AiPriceResult(
        suggestedPrice: 0,
        marketLow: 0,
        marketHigh: 0,
        fairDeal: false,
        suggestedPricePerBase: 0,
        baseUnit: base.baseUnit,
        confidence: AiConfidence.none,
        sampleCount: 0,
        source: "none",
        explanation: "Invalid quantity/unit.",
      );
    }

    // 1) Exact product + location
    var pairs = await _fetchPairs(
      normalizedTitle: norm,
      category: null,
      location: locationName,
      limit: limit,
    );

    var source = "exact";

    // 2) Category + location fallback (only if category is usable)
    if (pairs.length < 3 && category.isNotEmpty && category != "All") {
      final p2 = await _fetchPairs(
        normalizedTitle: null,
        category: category,
        location: locationName,
        limit: limit,
      );

      if (p2.length > pairs.length) {
        pairs = p2;
        source = "category_location";
      }
    }

    // 3) Category only fallback
    if (pairs.length < 3 && category.isNotEmpty && category != "All") {
      final p3 = await _fetchPairs(
        normalizedTitle: null,
        category: category,
        location: null,
        limit: limit,
      );

      if (p3.length > pairs.length) {
        pairs = p3;
        source = "category";
      }
    }

    // No sold history
    if (pairs.isEmpty) {
      return AiPriceResult(
        suggestedPrice: 0,
        marketLow: 0,
        marketHigh: 0,
        fairDeal: false,
        suggestedPricePerBase: 0,
        baseUnit: base.baseUnit,
        confidence: AiConfidence.none,
        sampleCount: 0,
        source: "none",
        explanation: "No sold history found yet.",
      );
    }

    final median = _median(pairs);

    // Market range (±15%) – safe for most products
    final lowPpb = median * 0.85;
    final highPpb = median * 1.15;

    final suggested = (median * base.baseQty).round();
    final low = (lowPpb * base.baseQty).round();
    final high = (highPpb * base.baseQty).round();

    // ✅ Fair deal: if user hasn't entered price yet -> true (don’t mark unfair)
    final userPpb = userPriceRs > 0 ? userPriceRs / base.baseQty : 0.0;
    final fair = (userPriceRs <= 0)
        ? true
        : (userPpb >= lowPpb && userPpb <= highPpb);

    final conf = _confidence(pairs.length);

    String explanation;
    if (source == "exact") {
      explanation =
          "Based on ${pairs.length} sold items for this product in $locationName.";
    } else if (source == "category_location") {
      explanation =
          "Based on ${pairs.length} sold items in $locationName (same category).";
    } else {
      explanation =
          "Based on ${pairs.length} sold items nationwide (same category).";
    }

    if (conf == AiConfidence.low) {
      explanation += " Low confidence (limited data).";
    } else if (conf == AiConfidence.none) {
      explanation += " Very low confidence.";
    }

    return AiPriceResult(
      suggestedPrice: suggested,
      marketLow: low,
      marketHigh: high,
      fairDeal: fair,
      suggestedPricePerBase: median,
      baseUnit: base.baseUnit,
      confidence: conf,
      sampleCount: pairs.length,
      source: source,
      explanation: explanation,
    );
  }
}

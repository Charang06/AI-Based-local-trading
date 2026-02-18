import 'package:cloud_firestore/cloud_firestore.dart';

class AiPriceResult {
  final int suggestedPrice; // for user's qty
  final int marketLow; // for user's qty
  final int marketHigh; // for user's qty
  final bool fairDeal;

  final double suggestedPricePerBase; // price per base unit
  final String baseUnit;

  const AiPriceResult({
    required this.suggestedPrice,
    required this.marketLow,
    required this.marketHigh,
    required this.fairDeal,
    required this.suggestedPricePerBase,
    required this.baseUnit,
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
  // Title normalizer for matching
  static String normalizeTitle(String title) {
    var t = title.toLowerCase().trim();

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

    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  // Base units:
  // - weight -> "kg"
  // - volume -> "l"
  // - count  -> "unit"
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

  /// ✅ ONLY SOLD DATA
  /// If no SOLD history exists => returns suggestedPrice=0 (UI should show "—")
  static Future<AiPriceResult> suggestFromHistory({
    required String title,
    required String locationName,
    required double userQty,
    required String userUnit,
    required int
    userPriceRs, // used only to compute fairDeal when suggestion exists
    int limit = 30,
  }) async {
    final norm = normalizeTitle(title);
    final userBase = toBase(userQty, userUnit);

    final qs = await FirebaseFirestore.instance
        .collection("products")
        .where("normalizedTitle", isEqualTo: norm)
        .where("locationName", isEqualTo: locationName)
        .where("status", isEqualTo: "sold")
        .orderBy("soldAt", descending: true)
        .limit(limit)
        .get();

    final ppbList = <double>[]; // price per base
    final weights = <double>[]; // faster sale => higher weight

    for (final doc in qs.docs) {
      final d = doc.data();

      // Prefer stored pricePerBase
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

      final createdAt = d["createdAt"];
      final soldAt = d["soldAt"];

      double w = 1.0;
      if (createdAt is Timestamp && soldAt is Timestamp) {
        final days = soldAt.toDate().difference(createdAt.toDate()).inDays;
        final dd = days < 1 ? 1 : (days > 60 ? 60 : days);
        w = 1.0 / dd;
      }

      ppbList.add(ppb);
      weights.add(w);
    }

    // ✅ NO SOLD HISTORY => NO SUGGESTION (do NOT copy user's price)
    if (ppbList.isEmpty) {
      return AiPriceResult(
        suggestedPrice: 0,
        marketLow: 0,
        marketHigh: 0,
        fairDeal: false,
        suggestedPricePerBase: 0,
        baseUnit: userBase.baseUnit,
      );
    }

    // Weighted median (robust)
    final pairs = List.generate(
      ppbList.length,
      (i) => (ppbList[i], weights[i]),
    );
    pairs.sort((a, b) => a.$1.compareTo(b.$1));

    final totalW = pairs.fold<double>(0, (s, e) => s + e.$2);
    double cum = 0;
    double medianPpb = pairs.first.$1;

    for (final (ppb, w) in pairs) {
      cum += w;
      if (cum >= totalW / 2) {
        medianPpb = ppb;
        break;
      }
    }

    final lowPpb = medianPpb * 0.85;
    final highPpb = medianPpb * 1.15;

    final suggested = (medianPpb * userBase.baseQty).round();
    final low = (lowPpb * userBase.baseQty).round();
    final high = (highPpb * userBase.baseQty).round();

    // fair deal check only if user entered price
    final userPpb = (userPriceRs > 0 && userBase.baseQty > 0)
        ? (userPriceRs / userBase.baseQty)
        : 0.0;

    final fair = (userPpb > 0)
        ? (userPpb >= lowPpb && userPpb <= highPpb)
        : true;

    return AiPriceResult(
      suggestedPrice: suggested,
      marketLow: low,
      marketHigh: high,
      fairDeal: fair,
      suggestedPricePerBase: medianPpb,
      baseUnit: userBase.baseUnit,
    );
  }
}

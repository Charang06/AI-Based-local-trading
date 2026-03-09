import '../services/negotiation_bot.dart';

class NegotiationSuggestions {
  /// Returns quick reply suggestions based on role + last offer.
  static List<String> build({
    required bool amSeller,
    required int sellerPriceRs,
    required int buyerOfferRs,
    int marketLow = 0,
    int marketHigh = 0,
    int round = 0,
  }) {
    // Use your existing bot logic to decide best response
    final decision = NegotiationBot.decide(
      sellerPriceRs: sellerPriceRs > 0 ? sellerPriceRs : 200,
      buyerOfferRs: buyerOfferRs > 0 ? buyerOfferRs : 1,
      marketLow: marketLow,
      marketHigh: marketHigh,
      round: round,
    );

    final counter = decision.counterOfferRs ?? 0;

    // Seller suggestions
    if (amSeller) {
      final list = <String>[];

      if (buyerOfferRs > 0) {
        list.add("Offer: Rs $buyerOfferRs"); // echo
      }

      if (decision.type == "counter" && counter > 0) {
        list.add("Offer: Rs $counter");
        list.add("I can do Rs $counter. Is that okay?");
      }

      if (decision.type == "accept") {
        list.add("Accepted ✅");
        list.add("Ok, deal at Rs $buyerOfferRs ✅");
      }

      if (decision.type == "reject") {
        list.add("Sorry, too low.");
        if (sellerPriceRs > 0) list.add("Offer: Rs $sellerPriceRs");
      }

      // Always useful
      list.add("Can you increase a little?");
      list.add("Final price please.");
      return _unique(list);
    }

    // Buyer suggestions
    final list = <String>[];

    // If buyer has not offered yet
    if (buyerOfferRs <= 0) {
      final startOffer = (sellerPriceRs * 0.8).round();
      list.add("Offer: Rs $startOffer");
      list.add("Can you reduce the price?");
      list.add("What is your best price?");
      return _unique(list);
    }

    // Buyer already offered
    final nextOffer = (buyerOfferRs + ((sellerPriceRs - buyerOfferRs) * 0.35))
        .round();
    final safeOffer = nextOffer.clamp(buyerOfferRs + 1, sellerPriceRs);

    list.add("Offer: Rs $safeOffer");
    list.add("I can buy now for Rs $safeOffer ✅");
    list.add("Can you accept Rs $safeOffer?");
    list.add("Please reduce a little.");

    return _unique(list);
  }

  static List<String> _unique(List<String> items) {
    final seen = <String>{};
    final out = <String>[];
    for (final x in items) {
      final t = x.trim();
      if (t.isEmpty) continue;
      if (seen.add(t)) out.add(t);
    }
    return out.take(6).toList(); // keep UI clean
  }
}

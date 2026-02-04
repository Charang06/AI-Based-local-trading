class BotDecision {
  final String type; // counter | accept | reject
  final String text;
  final int? counterOfferRs;

  const BotDecision({
    required this.type,
    required this.text,
    this.counterOfferRs,
  });
}

class NegotiationBot {
  static BotDecision decide({
    required int sellerPriceRs,
    required int buyerOfferRs,
    required int marketLow,
    required int marketHigh,
    required int round,
  }) {
    if (buyerOfferRs <= 0) {
      return const BotDecision(
        type: "reject",
        text: "Please enter a valid offer.",
      );
    }

    final low = marketLow > 0 ? marketLow : (sellerPriceRs * 0.85).round();
    final high = marketHigh > 0 ? marketHigh : (sellerPriceRs * 1.15).round();

    // too low → reject
    if (buyerOfferRs < (low * 0.75).round()) {
      return BotDecision(
        type: "reject",
        text: "❌ Too low. Market starts near Rs $low.",
      );
    }

    // accept if close enough
    if (buyerOfferRs >= (low * 0.98).round()) {
      return BotDecision(
        type: "accept",
        text: "✅ Deal accepted at Rs $buyerOfferRs",
      );
    }

    // counter strategy
    final concession = 0.08 + (round * 0.03); // round 0=8%, 3=17%
    int counter = (sellerPriceRs * (1 - concession)).round();

    // never go below low
    if (counter < low) counter = low;

    // if buyer almost reached, close quickly
    if ((counter - buyerOfferRs) <= 50) counter = buyerOfferRs + 20;

    if (counter > high) counter = high;

    return BotDecision(
      type: "counter",
      counterOfferRs: counter,
      text: "🤝 Counter offer: Rs $counter (Market Rs $low - Rs $high)",
    );
  }
}

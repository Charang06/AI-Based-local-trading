import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v2';

admin.initializeApp();

type NegotiationStatus = 'pending' | 'accepted' | 'rejected';

type BotDecisionType = 'counter' | 'accept' | 'reject';

interface BotDecision {
  type: BotDecisionType;
  text: string;
  counterOfferRs?: number;
}

interface NegotiationDoc {
  buyerId: string;
  sellerId: string;
  productId: string;
  productTitle: string;
  status?: NegotiationStatus;
  round?: number;
  sellerPriceRs?: number;
  marketLow?: number;
  marketHigh?: number;
}

interface MessageDoc {
  text: string;
  senderId: string;
  createdAt?: admin.firestore.Timestamp;
  type?: 'text' | 'offer';
  offerRs?: number;
}

function roundNice(value: number): number {
  if (value <= 0) return 0;
  return Math.round(value / 10) * 10;
}

function decideBot(params: {
  sellerPriceRs: number;
  buyerOfferRs: number;
  marketLow: number;
  marketHigh: number;
  round: number;
}): BotDecision {
  const seller = params.sellerPriceRs;
  const offer = params.buyerOfferRs;
  const low = params.marketLow;
  const high = params.marketHigh;
  const round = params.round;

  // Hard limits
  if (offer <= 0) {
    return {type: 'reject', text: 'Please send a valid offer amount.'};
  }

  // If we have market range, use it
  const hasMarket = low > 0 && high > 0;

  const targetHigh = hasMarket ? high : seller;
  const acceptLine = hasMarket ? Math.round(high * 0.95) : Math.round(seller * 0.95);
  const rejectLine = hasMarket ? Math.round(low * 0.60) : Math.round(seller * 0.60);

  // Accept
  if (offer >= acceptLine) {
    return {
      type: 'accept',
      text: `✅ Accepted. Deal at Rs ${offer}.`,
    };
  }

  // Reject (too low)
  if (offer < rejectLine) {
    return {
      type: 'reject',
      text: '❌ Too low. Please increase your offer.',
    };
  }

  // Counter logic (gets tougher each round)
  const toughness = Math.min(round, 5);
  const gap = targetHigh - offer;
  const push = Math.round(gap * (0.50 + toughness * 0.05)); // 50%..75%
  const counter = roundNice(offer + push);

  return {
    type: 'counter',
    counterOfferRs: counter,
    text: `🤝 Counter offer: Rs ${counter}. Can you do this?`,
  };
}

export const negotiationBotOnOffer = functions.firestore.onDocumentCreated(
    'negotiations/{negId}/messages/{msgId}',
    async (event) => {
      const snap = event.data;
      if (!snap) return;

      const msg = snap.data() as MessageDoc;
      const negId = event.params.negId as string;

      // Only react to numeric offers
      const offerRs = typeof msg.offerRs === 'number' ? msg.offerRs : 0;
      const isOffer = msg.type === 'offer' || offerRs > 0;

      if (!isOffer) return;

      const negRef = admin.firestore().collection('negotiations').doc(negId);
      const negSnap = await negRef.get();

      if (!negSnap.exists) return;

      const neg = negSnap.data() as NegotiationDoc;

      // Only respond when BUYER sends the offer
      if (msg.senderId !== neg.buyerId) return;

      // If already accepted/rejected, do nothing
      const status = (neg.status ?? 'pending') as NegotiationStatus;
      if (status !== 'pending') return;

      const round = typeof neg.round === 'number' ? neg.round : 0;
      const sellerPriceRs = typeof neg.sellerPriceRs === 'number' && neg.sellerPriceRs > 0 ?
      neg.sellerPriceRs :
      0;

      // Fallback seller price:
      // Prefer sellerPriceRs saved in negotiation doc.
      // If not available, try to read from product doc priceRs.
      let sellerAsk = sellerPriceRs;

      if (sellerAsk <= 0) {
        const productSnap = await admin
            .firestore()
            .collection('products')
            .doc(neg.productId)
            .get();

        const p = productSnap.data() ?? {};
        const priceRs = typeof p.priceRs === 'number' ? p.priceRs : 0;
        sellerAsk = priceRs > 0 ? priceRs : 200;
      }

      const marketLow = typeof neg.marketLow === 'number' ? neg.marketLow : 0;
      const marketHigh = typeof neg.marketHigh === 'number' ? neg.marketHigh : 0;

      const decision = decideBot({
        sellerPriceRs: sellerAsk,
        buyerOfferRs: offerRs,
        marketLow,
        marketHigh,
        round,
      });

      const msgCol = negRef.collection('messages');

      // Write bot message (Admin SDK bypasses rules)
      await msgCol.add({
        text: decision.text,
        senderId: 'bot',
        senderRole: 'bot',
        type: decision.type,
        offerRs: decision.counterOfferRs ?? 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update negotiation doc
      const update: Record<string, unknown> = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        round: round + 1,
        lastOfferRs: offerRs,
        lastOfferBy: neg.buyerId,
        lastMessage: decision.text,
      };

      if (decision.type === 'counter') {
        update.lastCounterRs = decision.counterOfferRs ?? 0;
        update.status = 'pending';
      }

      if (decision.type === 'accept') {
        update.status = 'accepted';
        update.acceptedPriceRs = offerRs;
      }

      if (decision.type === 'reject') {
        update.status = 'rejected';
      }

      await negRef.set(update, {merge: true});
    },
);

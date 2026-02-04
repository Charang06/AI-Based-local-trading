import 'package:cloud_firestore/cloud_firestore.dart';

class NegotiationService {
  NegotiationService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  String buildNegotiationId({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) {
    final a = buyerId.compareTo(sellerId) <= 0 ? buyerId : sellerId;
    final b = buyerId.compareTo(sellerId) <= 0 ? sellerId : buyerId;
    return "${productId}_${a}_$b";
  }

  DocumentReference<Map<String, dynamic>> negotiationDoc(String id) {
    return _db.collection("negotiations").doc(id);
  }

  CollectionReference<Map<String, dynamic>> messagesCol(String id) {
    return negotiationDoc(id).collection("messages");
  }

  Future<String> fetchSellerIdFromProduct(String productId) async {
    final snap = await _db.collection("products").doc(productId).get();
    final data = snap.data() ?? {};
    final sellerId = (data["sellerId"] ?? "").toString();
    if (sellerId.isEmpty) {
      throw Exception("Missing sellerId in products/$productId");
    }
    return sellerId;
  }

  Future<String> ensureNegotiation({
    required String productId,
    required String productTitle,
    required String buyerId,
    required String sellerId,
  }) async {
    final negotiationId = buildNegotiationId(
      productId: productId,
      buyerId: buyerId,
      sellerId: sellerId,
    );

    final ref = negotiationDoc(negotiationId);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        "productId": productId,
        "productTitle": productTitle,
        "buyerId": buyerId,
        "sellerId": sellerId,

        "participants": [buyerId, sellerId],

        "status": "pending", // ✅ required for ManageOffers tabs
        "round": 0,
        "lastOfferRs": 0,
        "lastCounterRs": 0,

        "lastMessage": "",
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    }

    return negotiationId;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(
    String negotiationId,
  ) {
    return messagesCol(
      negotiationId,
    ).orderBy("createdAt", descending: true).snapshots();
  }

  Future<void> sendMessage({
    required String negotiationId,
    required String senderId,
    required String senderRole, // buyer/seller/bot
    required String type, // text/offer/counter/accept/reject
    required String text,
    int? offerRs,
  }) async {
    final t = text.trim();
    if (t.isEmpty) return;

    await messagesCol(negotiationId).add({
      "text": t,
      "senderId": senderId,
      "senderRole": senderRole,
      "type": type,
      "offerRs": offerRs,
      "createdAt": FieldValue.serverTimestamp(),
    });

    await negotiationDoc(negotiationId).set({
      "lastMessage": t,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

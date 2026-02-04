import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static Stream<QuerySnapshot> streamMessages(String chatId) {
    return FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("timestamp")
        .snapshots();
  }

  static Future<void> sendMessage({
    required String chatId,
    required String text,
    required String senderId,
  }) {
    return FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .add({
      "text": text,
      "senderId": senderId,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../app_language.dart';
import '../models/product.dart';
import '../services/voice_assistant.dart';
import 'manage_offers_screen.dart';
import 'start_negotiation_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _autoSpoken = false;

  Product get product => widget.product;

  @override
  void initState() {
    super.initState();

    // ✅ Auto speak help once after UI loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _autoSpoken) return;
      _autoSpoken = true;

      final lang = AppLanguage.current.value;
      await _speakDetailGuide(lang);
    });
  }

  @override
  void dispose() {
    VoiceAssistant.instance.stop();
    super.dispose();
  }

  // ✅ Real internet check
  Future<bool> _isOnline() async {
    try {
      return await InternetConnection().hasInternetAccess;
    } catch (_) {
      return true; // fallback
    }
  }

  // =========================
  // ✅ Translations EN / SI / TA
  // =========================
  String _t(AppLang lang, String key) {
    const en = {
      "seller": "Seller",
      "description": "📌 Description",
      "status_sold": "Status: SOLD",
      "status_active": "Status: ACTIVE",
      "fair_deal": "Fair Deal",
      "check": "Check",
      "start_negotiation": "Start Negotiation",
      "buy_now": "Buy Now",
      "manage_offers": "Manage Offers",
      "mark_sold": "Mark as Sold",
      "already_sold": "Already Sold",
      "sold_msg": "This product is already sold.",
      "login_first": "Please login first.",
      "you_are_seller": "You are the seller of this product.",
      "buy_now_title": "Buy Now",
      "qty": "Quantity",
      "delivery_address": "Delivery Address",
      "note_optional": "Note (optional)",
      "payment": "Payment",
      "cash": "Cash",
      "card": "Card",
      "place_order": "Place Order",
      "enter_valid_qty": "Enter valid quantity.",
      "enter_address": "Enter delivery address.",
      "offline_sold": "Offline: Marked as SOLD locally ✅ Will sync later.",
      "marked_sold": "Marked as sold ✅",
      "sold_fail": "Failed to mark as sold:",
      "offline_order_saved": "Offline ✅ Order saved. Will sync.",
      "order_placed": "Order placed ✅",
      "network_saved_offline": "Network issue. Saved offline ✅",
      "order_failed": "Order failed:",
      "help": "Help",
      "stop": "Stop",
      "read": "Read",
      "ai": "AI",
    };

    const si = {
      "seller": "විකුණුම්කරු",
      "description": "📌 විස්තරය",
      "status_sold": "තත්ත්වය: විකිණී ඇත",
      "status_active": "තත්ත්වය: සක්‍රීයයි",
      "fair_deal": "සාධාරණයි",
      "check": "පරීක්ෂා කරන්න",
      "start_negotiation": "කතාබහ අරඹන්න",
      "buy_now": "දැන් මිලදී ගන්න",
      "manage_offers": "යෝජනා කළමනාකරණය",
      "mark_sold": "විකුණූ ලෙස සටහන් කරන්න",
      "already_sold": "දැනටමත් විකිණී ඇත",
      "sold_msg": "මෙම භාණ්ඩය දැනටමත් විකිණී ඇත.",
      "login_first": "කරුණාකර පළමුව ලොගින් වන්න.",
      "you_are_seller": "ඔබ මෙම භාණ්ඩයේ විකුණුම්කරුවාය.",
      "buy_now_title": "දැන් මිලදී ගන්න",
      "qty": "ප්‍රමාණය",
      "delivery_address": "බෙදාහැරීමේ ලිපිනය",
      "note_optional": "සටහන (විකල්ප)",
      "payment": "ගෙවීම",
      "cash": "මුදල්",
      "card": "කාඩ්",
      "place_order": "ඇණවුම යොදන්න",
      "enter_valid_qty": "වලංගු ප්‍රමාණයක් දමන්න.",
      "enter_address": "ලිපිනය දමන්න.",
      "offline_sold": "Offline: SOLD ලෙස සුරකිණි ✅ පසුව Sync වේ.",
      "marked_sold": "විකුණූ ලෙස සටහන් විය ✅",
      "sold_fail": "විකුණූ ලෙස සටහන් කිරීම අසාර්ථකයි:",
      "offline_order_saved": "Offline ✅ ඇණවුම සුරකිණි. පසුව Sync වේ.",
      "order_placed": "ඇණවුම යොදා ඇත ✅",
      "network_saved_offline": "ජාල ගැටළුවක්. Offline ලෙස සුරකිණි ✅",
      "order_failed": "ඇණවුම අසාර්ථකයි:",
      "help": "උදව්",
      "stop": "නවතන්න",
      "read": "කියවන්න",
      "ai": "AI",
    };

    const ta = {
      "seller": "விற்பனையாளர்",
      "description": "📌 விவரம்",
      "status_sold": "நிலை: விற்கப்பட்டது",
      "status_active": "நிலை: செயலில்",
      "fair_deal": "நல்ல விலை",
      "check": "சரி பார்க்க",
      "start_negotiation": "பேச்சுவார்த்தை தொடங்கு",
      "buy_now": "இப்போது வாங்கு",
      "manage_offers": "சலுகைகளை நிர்வகிக்க",
      "mark_sold": "விற்கப்பட்டது என குறி",
      "already_sold": "ஏற்கனவே விற்கப்பட்டது",
      "sold_msg": "இந்த பொருள் ஏற்கனவே விற்கப்பட்டது.",
      "login_first": "முதலில் உள்நுழையவும்.",
      "you_are_seller": "நீங்கள் இந்த பொருளின் விற்பனையாளர்.",
      "buy_now_title": "இப்போது வாங்கு",
      "qty": "அளவு",
      "delivery_address": "விநியோக முகவரி",
      "note_optional": "குறிப்பு (விருப்பம்)",
      "payment": "கட்டணம்",
      "cash": "பணம்",
      "card": "கார்டு",
      "place_order": "ஆர்டர் இடு",
      "enter_valid_qty": "சரியான அளவை உள்ளிடவும்.",
      "enter_address": "முகவரியை உள்ளிடவும்.",
      "offline_sold": "Offline: SOLD என்று சேமிக்கப்பட்டது ✅ பின்னர் Sync.",
      "marked_sold": "விற்கப்பட்டது என குறிக்கப்பட்டது ✅",
      "sold_fail": "விற்கப்பட்டது என குறிக்க முடியவில்லை:",
      "offline_order_saved": "Offline ✅ ஆர்டர் சேமிக்கப்பட்டது. பின்னர் Sync.",
      "order_placed": "ஆர்டர் இடப்பட்டது ✅",
      "network_saved_offline": "நெட்வொர்க் பிரச்சனை. Offline சேமிக்கப்பட்டது ✅",
      "order_failed": "ஆர்டர் தோல்வி:",
      "help": "உதவி",
      "stop": "நிறுத்து",
      "read": "படிக்க",
      "ai": "AI",
    };

    final map = (lang == AppLang.si) ? si : (lang == AppLang.ta ? ta : en);
    return map[key] ?? key;
  }

  // =========================
  // ✅ Voice helpers
  // =========================
  String _ttsLangCode(AppLang lang) {
    if (lang == AppLang.si) return "si-LK";
    if (lang == AppLang.ta) return "ta-IN";
    return "en-US";
  }

  Future<void> _speakDetailGuide(AppLang lang) async {
    await VoiceAssistant.instance.stop();
    final langCode = _ttsLangCode(lang);

    String text;
    if (lang == AppLang.si) {
      text =
          "මෙය භාණ්ඩ විස්තර තිරයයි. පහළින් කතාබහ අරඹන්න හෝ දැන් මිලදී ගන්න බොත්තම් ඇත. "
          "ඔබ විකුණුම්කරු නම් යෝජනා කළමනාකරණය සහ විකුණූ ලෙස සටහන් කරන්න බොත්තම් පෙන්වයි. "
          "ඉහළ Stop බොත්තමෙන් කථනය නවතන්න. Read බොත්තමෙන් සාරාංශය අහන්න.";
    } else if (lang == AppLang.ta) {
      text =
          "இது பொருள் விவர திரை. கீழே பேச்சுவார்த்தை தொடங்கு அல்லது இப்போது வாங்கு பொத்தான்கள் இருக்கும். "
          "நீங்கள் விற்பனையாளர் என்றால் சலுகைகளை நிர்வகிக்க மற்றும் விற்கப்பட்டது என குறி பொத்தான்கள் வரும். "
          "மேல் Stop மூலம் பேசுவதை நிறுத்தலாம். Read மூலம் சுருக்கம் கேட்கலாம்.";
    } else {
      text =
          "This is the Product Details screen. Use Start Negotiation or Buy Now at the bottom. "
          "If you are the seller, you will see Manage Offers and Mark as Sold. "
          "Use Stop to cancel speaking. Use Read to hear a short summary.";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  Future<void> _speakSummary(AppLang lang) async {
    await VoiceAssistant.instance.stop();
    final langCode = _ttsLangCode(lang);

    final isSold = product.status == "sold";
    final aiPrice = (product.aiPriceRs == 0)
        ? product.priceRs
        : product.aiPriceRs;

    String text;
    if (lang == AppLang.si) {
      text =
          "${product.title}. මිල රුපියල් ${product.priceRs}. ප්‍රමාණය ${product.qty} ${product.unit}. "
          "ස්ථානය ${product.locationName}. "
          "${product.fairDeal ? "සාධාරණ ගනුදෙනුවක්." : "මිල පරීක්ෂා කරන්න."} "
          "AI මිල රුපියල් $aiPrice. "
          "${isSold ? "තත්ත්වය විකිණී ඇත." : "තත්ත්වය සක්‍රීයයි."}";
    } else if (lang == AppLang.ta) {
      text =
          "${product.title}. விலை ரூபாய் ${product.priceRs}. அளவு ${product.qty} ${product.unit}. "
          "இடம் ${product.locationName}. "
          "${product.fairDeal ? "இது நல்ல விலை." : "விலையை சரி பார்க்கவும்."} "
          "AI விலை ரூபாய் $aiPrice. "
          "${isSold ? "நிலை விற்கப்பட்டது." : "நிலை செயலில்."}";
    } else {
      text =
          "${product.title}. Price rupees ${product.priceRs}. Quantity ${product.qty} ${product.unit}. "
          "Location ${product.locationName}. "
          "${product.fairDeal ? "This is a fair deal." : "Please check the price."} "
          "AI price is $aiPrice. "
          "${isSold ? "Status is sold." : "Status is active."}";
    }

    await VoiceAssistant.instance.init(languageCode: langCode);
    await VoiceAssistant.instance.speak(text);
  }

  // =========================
  // ✅ SOLD (offline + online)
  // =========================
  Future<void> _markAsSold(BuildContext context, AppLang lang) async {
    final online = await _isOnline();

    if (!online) {
      try {
        final outbox = Hive.box('outbox');
        final productsCache = Hive.box('products_cache');

        final cachedRaw = productsCache.get(product.id);
        final cached = (cachedRaw is Map)
            ? Map<String, dynamic>.from(cachedRaw)
            : <String, dynamic>{};

        cached["status"] = "sold";
        cached["soldAtLocal"] = DateTime.now().toIso8601String();
        productsCache.put(product.id, cached);

        outbox.add({
          "type": "fs_update",
          "path": "products/${product.id}",
          "data": {
            "status": "sold",
            "soldAtLocal": DateTime.now().toIso8601String(),
          },
          "createdAt": DateTime.now().toIso8601String(),
          "retryCount": 0,
        });

        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_t(lang, "offline_sold"))));
        Navigator.pop(context);
        return;
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Offline save failed: $e")));
        return;
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection("products")
          .doc(product.id)
          .update({"status": "sold", "soldAt": FieldValue.serverTimestamp()});

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "marked_sold"))));
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${_t(lang, "sold_fail")} $e")));
    }
  }

  // =========================
  // ✅ BUY NOW (offline + online)
  // =========================
  Future<void> _buyNow(BuildContext context, AppLang lang) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "login_first"))));
      return;
    }

    if (user.uid == product.sellerId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "you_are_seller"))));
      return;
    }

    final qtyCtrl = TextEditingController(text: product.qty.toString());
    final addressCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String paymentMethod = "cash";

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(lang, "buy_now_title"),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: "${_t(lang, "qty")} (${product.unit})",
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: _t(lang, "delivery_address"),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: _t(lang, "note_optional"),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _t(lang, "payment"),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: paymentMethod,
                        items: [
                          DropdownMenuItem(
                            value: "cash",
                            child: Text(_t(lang, "cash")),
                          ),
                          DropdownMenuItem(
                            value: "card",
                            child: Text(_t(lang, "card")),
                          ),
                        ],
                        onChanged: (v) =>
                            setSheet(() => paymentMethod = v ?? "cash"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                      ),
                      label: Text(
                        _t(lang, "place_order"),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        );
      },
    );

    if (ok != true) return;

    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
    final address = addressCtrl.text.trim();
    final note = noteCtrl.text.trim();

    if (qty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "enter_valid_qty"))));
      return;
    }
    if (address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "enter_address"))));
      return;
    }

    final totalRs = (product.priceRs * qty).round();
    final orderId = FirebaseFirestore.instance.collection("orders").doc().id;

    final orderData = <String, dynamic>{
      "orderId": orderId,
      "productId": product.id,
      "productTitle": product.title,
      "productImageUrl": product.imageUrl,
      "qty": qty,
      "unit": product.unit,
      "priceRs": product.priceRs,
      "totalRs": totalRs,
      "buyerId": user.uid,
      "buyerName": "Buyer",
      "buyerPhone": user.phoneNumber ?? "",
      "sellerId": product.sellerId,
      "deliveryAddress": address,
      "note": note,
      "paymentMethod": paymentMethod,
      "paymentStatus": "unpaid",
      "status": "pending",
      "hasUnreadForSeller": true,
      "hasUnreadForBuyer": false,
      "createdAtLocal": DateTime.now().toIso8601String(),
      "updatedAtLocal": DateTime.now().toIso8601String(),
    };

    final online = await _isOnline();

    if (!online) {
      try {
        final outbox = Hive.box('outbox');
        final ordersCache = Hive.box('orders_cache');

        ordersCache.put(orderId, {...orderData, "syncStatus": "pending"});

        outbox.add({
          "type": "fs_set",
          "path": "orders/$orderId",
          "data": orderData,
          "createdAt": DateTime.now().toIso8601String(),
          "retryCount": 0,
        });

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t(lang, "offline_order_saved"))),
        );
        Navigator.pop(context);
        return;
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Offline save failed: $e")));
        return;
      }
    }

    try {
      await FirebaseFirestore.instance.collection("orders").doc(orderId).set({
        ...orderData,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      try {
        Hive.box(
          'orders_cache',
        ).put(orderId, {...orderData, "syncStatus": "synced"});
      } catch (_) {}

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t(lang, "order_placed"))));
      Navigator.pop(context);
    } catch (e) {
      try {
        final outbox = Hive.box('outbox');
        final ordersCache = Hive.box('orders_cache');

        ordersCache.put(orderId, {...orderData, "syncStatus": "pending"});
        outbox.add({
          "type": "fs_set",
          "path": "orders/$orderId",
          "data": orderData,
          "createdAt": DateTime.now().toIso8601String(),
          "retryCount": 0,
        });

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${_t(lang, "network_saved_offline")}\n$e")),
        );
        Navigator.pop(context);
      } catch (e2) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${_t(lang, "order_failed")} $e2")),
        );
      }
    }
  }

  // =========================
  // ✅ UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.current,
      builder: (context, lang, _) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final isOwner = uid != null && uid == product.sellerId;
        final isSold = product.status == "sold";

        return Scaffold(
          body: Stack(
            children: [
              SizedBox(
                height: 320,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFFE5E7EB),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFE5E7EB),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _circleBtn(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _circleBtn(
                        icon: Icons.stop,
                        onTap: () => VoiceAssistant.instance.stop(),
                      ),
                      const SizedBox(width: 8),
                      _circleBtn(
                        icon: Icons.record_voice_over,
                        onTap: () => _speakSummary(lang),
                      ),
                      const SizedBox(width: 8),
                      _circleBtn(
                        icon: Icons.volume_up,
                        onTap: () => _speakDetailGuide(lang),
                      ),
                      const SizedBox(width: 8),
                      _fairDealChip(product.fairDeal, lang),
                    ],
                  ),
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.64,
                minChildSize: 0.58,
                maxChildSize: 0.92,
                builder: (context, controller) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 170),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                    ),
                    child: ListView(
                      controller: controller,
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${product.qty} ${product.unit}",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "Rs ${product.priceRs}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _aiChip(
                              lang,
                              (product.aiPriceRs == 0)
                                  ? product.priceRs
                                  : product.aiPriceRs,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSold
                                  ? const Color(0xFFE5E7EB)
                                  : const Color(0xFFEAF7FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isSold
                                  ? _t(lang, "status_sold")
                                  : _t(lang, "status_active"),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: isSold
                                    ? Colors.black54
                                    : const Color(0xFF2A7BF4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4FFFA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 22,
                                backgroundColor: Color(0xFFE7F6FF),
                                child: Icon(
                                  Icons.person,
                                  color: Color(0xFF2A7BF4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _t(lang, "seller"),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      product.sellerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _t(lang, "description"),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(product.description),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  children: [
                    if (!isOwner) ...[
                      _actionBtn(
                        text: _t(lang, "start_negotiation"),
                        color: const Color(0xFF2A7BF4),
                        icon: Icons.chat_bubble_outline,
                        onTap: isSold
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_t(lang, "sold_msg"))),
                              )
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StartNegotiationScreen(product: product),
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      _actionBtn(
                        text: _t(lang, "buy_now"),
                        color: const Color(0xFF22C55E),
                        icon: Icons.shopping_cart_outlined,
                        onTap: isSold ? () {} : () => _buyNow(context, lang),
                      ),
                    ],
                    if (isOwner) ...[
                      _actionBtn(
                        text: _t(lang, "manage_offers"),
                        color: const Color(0xFF2A7BF4),
                        icon: Icons.work_outline,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageOffersScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _actionBtn(
                        text: isSold
                            ? _t(lang, "already_sold")
                            : _t(lang, "mark_sold"),
                        color: isSold ? Colors.grey : const Color(0xFFF97316),
                        icon: Icons.check_circle_outline,
                        onTap: isSold
                            ? () {}
                            : () => _markAsSold(context, lang),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon),
      ),
    );
  }

  Widget _fairDealChip(bool fair, AppLang lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
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

  Widget _aiChip(AppLang lang, int aiPrice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        "✨ ${_t(lang, "ai")}: Rs $aiPrice",
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFF7C3AED),
        ),
      ),
    );
  }

  Widget _actionBtn({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

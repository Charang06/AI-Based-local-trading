import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import 'start_negotiation_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  Future<void> _markAsSold(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection("products")
          .doc(product.id)
          .update({"status": "sold", "soldAt": FieldValue.serverTimestamp()});

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Marked as sold ✅")));

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to mark as sold: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = uid != null && uid == product.sellerId;
    final isSold = product.status == "sold";

    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: 320,
            width: double.infinity,
            child: Image.network(product.imageUrl, fit: BoxFit.cover),
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
                  _fairDealChip(product.fairDeal),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                          product.aiPriceRs == 0
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
                          isSold ? "Status: SOLD" : "Status: ACTIVE",
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
                            child: Icon(Icons.person, color: Color(0xFF2A7BF4)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Seller",
                                  style: TextStyle(color: Colors.black54),
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

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F2FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "AI Price Analysis",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (product.marketLow == 0 || product.marketHigh == 0)
                                ? "No SOLD history yet for this product + location."
                                : "Market range in your area.",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Market Low\nRs ${product.marketLow}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                "Market High\nRs ${product.marketHigh}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Text(
                      "📌 Description",
                      style: TextStyle(fontWeight: FontWeight.w900),
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
                _actionBtn(
                  text: "Start Negotiation",
                  color: const Color(0xFF2A7BF4),
                  icon: Icons.chat_bubble_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StartNegotiationScreen(product: product),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                _actionBtn(
                  text: "Buy Now",
                  color: const Color(0xFF22C55E),
                  icon: Icons.shopping_cart_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Buy Now (next feature)")),
                    );
                  },
                ),

                // ✅ only owner sees this
                if (isOwner) ...[
                  const SizedBox(height: 10),
                  _actionBtn(
                    text: isSold ? "Already Sold" : "Mark as Sold",
                    color: isSold ? Colors.grey : const Color(0xFFF97316),
                    icon: Icons.check_circle_outline,
                    onTap: isSold
                        ? () {}
                        : () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Mark as Sold?"),
                                content: const Text(
                                  "This will hide from buyers and help AI learn.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("Yes, Sold"),
                                  ),
                                ],
                              ),
                            );

                            if (ok == true) {
                              await _markAsSold(context);
                            }
                          },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon),
      ),
    );
  }

  Widget _fairDealChip(bool fair) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
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
            fair ? "Fair Deal" : "Check",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: fair ? Colors.green : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiChip(int aiPrice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        "✨ AI: Rs $aiPrice",
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

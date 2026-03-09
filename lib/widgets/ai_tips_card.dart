import 'package:flutter/material.dart';

class AiTipCard extends StatelessWidget {
  final String title;
  final String tip;
  final VoidCallback? onNext;

  const AiTipCard({
    super.key,
    required this.title,
    required this.tip,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4C1D95),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onNext != null)
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.refresh, color: Color(0xFF7C3AED)),
            ),
        ],
      ),
    );
  }
}

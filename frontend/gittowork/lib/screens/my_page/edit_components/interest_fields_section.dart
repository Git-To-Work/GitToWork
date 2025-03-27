import 'dart:math';
import 'package:flutter/material.dart';

class InterestFieldsSection extends StatelessWidget {
  final List<String> interestFields;
  final VoidCallback onEditPressed;

  const InterestFieldsSection({
    super.key,
    required this.interestFields,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 360,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onEditPressed,
            child: const Text('관심 비즈니스 분야 수정', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        if (interestFields.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: interestFields.take(5).map((field) {
                final randomColor = _getRandomColor();
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: randomColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(field, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Color _getRandomColor() {
    final random = Random();
    final r = random.nextInt(100) + 100;
    final g = random.nextInt(100) + 100;
    final b = random.nextInt(100) + 100;
    return Color.fromARGB(255, r, g, b);
  }
}

import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar_back.dart';
import 'lucky_input.dart';
import 'lucky_result.dart';

class LuckyScreen extends StatefulWidget {
  const LuckyScreen({super.key});

  @override
  State<LuckyScreen> createState() => _LuckyScreenState();
}

class _LuckyScreenState extends State<LuckyScreen> {
  int selectedCategoryIndex = 0;
  final categories = ['전체', '학업', '애정', '재물'];

  final TextEditingController birthDateController = TextEditingController();
  String selectedTime = '13:00 ~ 13:30';
  String selectedGender = '여성';
  bool showResult = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: const CustomBackAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        child: Column(
          children: [
            // 🔹 버튼 4개 + 간격 10 적용
            LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                const gap = 10.0;
                const buttonCount = 4;
                final buttonWidth = (totalWidth - (gap * (buttonCount - 1))) / buttonCount;

                return Row(
                  children: List.generate(categories.length * 2 - 1, (i) {
                    if (i.isOdd) return const SizedBox(width: gap);
                    final index = i ~/ 2;
                    return SizedBox(
                      width: buttonWidth,
                      child: _buildCategoryCard(index),
                    );
                  }),
                );
              },
            ),

            const SizedBox(height: 24),

            // 입력 폼
            LuckyInput(
              onSubmit: () => setState(() => showResult = true),
            ),

            const SizedBox(height: 20),

            if (showResult) const LuckyResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(int index) {
    final isSelected = selectedCategoryIndex == index;

    final icons = [
      Icons.pets,
      Icons.school,
      Icons.favorite,
      Icons.attach_money,
    ];

    final categoryColors = [
      const Color(0xFF00C853),
      const Color(0xFF2196F3),
      const Color(0xFFFF4081),
      const Color(0xFFDAA520),
    ];

    final selectedColor = categoryColors[index];

    return GestureDetector(
      onTap: () => setState(() => selectedCategoryIndex = index),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isSelected ? selectedColor.withValues(alpha: 0.25) : Colors.black12,

              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icons[index],
              size: 24,
              color: isSelected ? selectedColor : const Color(0xFF666666),
            ),
            const SizedBox(height: 4),
            Text(
              categories[index],
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? selectedColor : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

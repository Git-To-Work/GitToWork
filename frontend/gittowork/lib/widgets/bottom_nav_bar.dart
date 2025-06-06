import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  // 재사용 가능한 버튼 빌더 함수
  Widget _buildNavButton({
    required int index,
    required String assetPath,
  }) {
    final bool isSelected = (index == selectedIndex);
    return SizedBox(
      width: 67,
      height: 55,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: () => onItemTapped(index),
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              border: isSelected
                  ? Border.all(color: const Color(0xFFD6D6D6), width: 1.0)
                  : null,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 4,
                )
              ]
                  : [],
            ),
            child: Image.asset(
              assetPath,
              height: 40,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, // 하단바 전체 높이
      decoration: BoxDecoration(
        color: Colors.white, // 하단바 배경색 흰색
        border: const Border(
          top: BorderSide(
            color: Color(0xFFD6D6D6), // 상단 외곽선 색상
            width: 1.0, // 외곽선 두께
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNavButton(index: 0, assetPath: 'assets/images/Home.png'),
            const SizedBox(width: 6),
            _buildNavButton(index: 1, assetPath: 'assets/images/Company.png'),
            const SizedBox(width: 6),
            _buildNavButton(index: 2, assetPath: 'assets/images/Cover_Letter.png'),
            const SizedBox(width: 6),
            _buildNavButton(index: 3, assetPath: 'assets/images/Entertainment.png'),
            const SizedBox(width: 6),
            _buildNavButton(index: 4, assetPath: 'assets/images/My_Page.png'),
          ],
        ),
      ),
    );
  }
}

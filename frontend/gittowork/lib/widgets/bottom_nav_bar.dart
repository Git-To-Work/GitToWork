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

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0), // 버튼 간 간격
        child: Material(
          // Material의 배경을 투명하게 설정하여 Container의 decoration이 그대로 보이게 함.
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          child: InkWell(
            onTap: () => onItemTapped(index),
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              alignment: Alignment.center,
              // Container에 배경색과 외곽선, 그림자 효과를 적용
              decoration: BoxDecoration(
                color: Colors.white, // 버튼 배경은 흰색
                border: isSelected
                    ? Border.all(color: Color(0xFFD6D6D6), width: 1.0)
                    : null,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    offset: Offset(0, 4), // x: 0, y: 4
                    blurRadius: 4, // 블러 4
                  ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120, // 원하는 높이로 설정
      child: BottomAppBar(
        color: Colors.white, // 하단바 배경색 흰색
        child: Padding(
          // 좌우 16, 상단 8의 간격
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
          child: Row(
            children: [
              _buildNavButton(index: 0, assetPath: 'assets/images/Home.png'),
              _buildNavButton(index: 1, assetPath: 'assets/images/Company.png'),
              _buildNavButton(index: 2, assetPath: 'assets/images/CoverLetter.png'),
              _buildNavButton(index: 3, assetPath: 'assets/images/Entertainment.png'),
              _buildNavButton(index: 4, assetPath: 'assets/images/MyPage.png'),
            ],
          ),
        ),
      ),
    );
  }
}

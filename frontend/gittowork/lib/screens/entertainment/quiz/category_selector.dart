import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String currentCategory;
  final Function(String) onCategoryChanged;

  const CategorySelector({
    Key? key,
    required this.currentCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  // 4가지 카테고리: 자소서(CL), 컴퓨터 과학(CS), 인성면접(FI), 기술 스택(SS)
  final Map<String, String> categories = const {
    'CL': '자소서',
    'CS': '컴퓨터 과학',
    'FI': '인성면접',
    'SS': '기술 스택',
  };

  // 현재 카테고리에 따라 원의 위치를 대략적으로 결정 (간단 예시)
  Offset _calcCircleOffset(String category) {
    switch (category) {
      case 'CL': // 자소서
        return const Offset(0, 0);
      case 'CS': // 컴퓨터 과학
        return const Offset(20, 0);
      case 'FI': // 인성면접
        return const Offset(0, 20);
      case 'SS': // 기술 스택
        return const Offset(20, 20);
      default:
      // 선택되지 않았을 때 (빈 문자열 등)
        return const Offset(10, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Offset circleOffset = _calcCircleOffset(currentCategory);

    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 왼쪽 위: 자소서
          Positioned(
            top: 0,
            left: 0,
            child: GestureDetector(
              onTap: () => onCategoryChanged('CL'),
              child: Text(
                categories['CL']!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: currentCategory == 'CL' ? FontWeight.bold : FontWeight.normal,
                  color: currentCategory == 'CL' ? Colors.blue : Colors.black,
                ),
              ),
            ),
          ),
          // 오른쪽 위: 컴퓨터 과학
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => onCategoryChanged('CS'),
              child: Text(
                categories['CS']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: currentCategory == 'CS' ? FontWeight.bold : FontWeight.normal,
                  color: currentCategory == 'CS' ? Colors.blue : Colors.black,
                ),
              ),
            ),
          ),
          // 왼쪽 아래: 인성면접
          Positioned(
            bottom: 0,
            left: 0,
            child: GestureDetector(
              onTap: () => onCategoryChanged('FI'),
              child: Text(
                categories['FI']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: currentCategory == 'FI' ? FontWeight.bold : FontWeight.normal,
                  color: currentCategory == 'FI' ? Colors.blue : Colors.black,
                ),
              ),
            ),
          ),
          // 오른쪽 아래: 기술 스택
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => onCategoryChanged('SS'),
              child: Text(
                categories['SS']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: currentCategory == 'SS' ? FontWeight.bold : FontWeight.normal,
                  color: currentCategory == 'SS' ? Colors.blue : Colors.black,
                ),
              ),
            ),
          ),
          // 중앙에 박스 (C5D5FF 배경) + 안의 움직이는 원
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFC5D5FF),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    left: circleOffset.dx,
                    top: circleOffset.dy,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

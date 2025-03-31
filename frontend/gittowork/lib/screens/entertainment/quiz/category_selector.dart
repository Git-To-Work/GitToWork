import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String currentCategory;
  final Function(String) onCategoryChanged;

  const CategorySelector({
    Key? key,
    required this.currentCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  // 카테고리 코드와 표시할 이름 매핑
  final Map<String, String> categories = const {
    'CL': '자소서',
    'CS': '컴퓨터 과학',
    'FI': '인성면접',
    'SS': '기술 스택',
  };

  // 선택된 카테고리에 따라 원의 위치를 결정 (간단 예시)
  double _calcCircleLeft(String category) {
    final keys = categories.keys.toList();
    int index = keys.indexOf(category);
    // 아직 선택되지 않은 경우 중앙 정렬(또는 원하는 기본 위치)
    if (index == -1) return 15.0;
    // 각 카테고리 간 간격을 15.0으로 가정
    return index * 15.0;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          // 카테고리 텍스트들을 나열
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: categories.entries.map((entry) {
              return GestureDetector(
                onTap: () {
                  onCategoryChanged(entry.key);
                },
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: currentCategory == entry.key ? FontWeight.bold : FontWeight.normal,
                    color: currentCategory == entry.key ? Colors.blue : Colors.black,
                  ),
                ),
              );
            }).toList(),
          ),
          // 중앙의 사각형 영역과 이동하는 원
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
                    left: _calcCircleLeft(currentCategory),
                    top: 15,
                    child: Container(
                      width: 30,
                      height: 30,
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

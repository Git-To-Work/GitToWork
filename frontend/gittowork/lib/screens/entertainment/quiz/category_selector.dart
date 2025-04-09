import 'package:flutter/material.dart';

class CategorySelector extends StatefulWidget {
  final String initialCategory;
  final ValueChanged<String> onCategoryChanged;

  const CategorySelector({
    super.key,
    required this.initialCategory,
    required this.onCategoryChanged,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  // Widget이 만들어질 때, 부모에서 받은 카테고리를 초기값으로 세팅
  late String _selectedCategory;

  // 4가지 카테고리
  final Map<String, String> categories = const {
    'CL': '자소서',
    'CS': '컴퓨터 과학',
    'FI': '인성면접',
    'SS': '기술 스택',
  };

  final Map<String, IconData> categoryIcons = {
    'CL': Icons.article,   // 자소서
    'CS': Icons.computer,  // 컴퓨터 과학
    'FI': Icons.person,    // 인성면접
    'SS': Icons.build,     // 기술 스택
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  // 선택된 카테고리에 따라 원 위치를 계산
  Offset _calcCircleOffset(String category) {
    switch (category) {
      case 'CL': // 좌상단
        return const Offset(5, 5);
      case 'CS': // 우상단
        return const Offset(45, 5);
      case 'FI': // 좌하단
        return const Offset(5, 45);
      case 'SS': // 우하단
        return const Offset(45, 45);
      default:
      // 선택되지 않았을 때 (임의로 중앙)
        return const Offset(27.5, 10);
    }
  }

  void _handleCategoryTap(String newCategory) {
    // 로컬 State를 먼저 바꾸어 원 이동 애니메이션 시작
    setState(() {
      _selectedCategory = newCategory;
    });
    // 그리고 부모(QuizScreen)에게도 알림 (새 퀴즈 가져오기 등)
    widget.onCategoryChanged(newCategory);
  }

  @override
  Widget build(BuildContext context) {
    final offset = _calcCircleOffset(_selectedCategory);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF454545).withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          const BoxShadow(
            color: Colors.black12,
          ),
          const BoxShadow(
            color: Colors.white,
            spreadRadius: -2.0,
            blurRadius: 2.0,
          ),
        ],
      ),
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 왼쪽 위: 자소서
          Positioned(
            top: 0,
            left: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 30, 0, 0),
              child: GestureDetector(
                onTap: () => _handleCategoryTap('CL'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      categoryIcons['CL'],
                      color: _selectedCategory == 'CL' ? Colors.blue : Colors.black,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      categories['CL']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedCategory == 'CL'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedCategory == 'CL'
                            ? Colors.blue
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 오른쪽 위: 컴퓨터 과학
          Positioned(
            top: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 30, 30, 0),
              child: GestureDetector(
                onTap: () => _handleCategoryTap('CS'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      categoryIcons['CS'],
                      color: _selectedCategory == 'CS' ? Colors.blue : Colors.black,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      categories['CS']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedCategory == 'CS'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedCategory == 'CS'
                            ? Colors.blue
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 왼쪽 아래: 인성면접
          Positioned(
            bottom: 0,
            left: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 0, 30),
              child: GestureDetector(
                onTap: () => _handleCategoryTap('FI'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      categoryIcons['FI'],
                      color: _selectedCategory == 'FI' ? Colors.blue : Colors.black,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      categories['FI']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        _selectedCategory == 'FI' ? FontWeight.bold : FontWeight.normal,
                        color: _selectedCategory == 'FI' ? Colors.blue : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 오른쪽 아래: 기술 스택
          Positioned(
            bottom: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 30, 30),
              child: GestureDetector(
                onTap: () => _handleCategoryTap('SS'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      categoryIcons['SS'],
                      color: _selectedCategory == 'SS' ? Colors.blue : Colors.black,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      categories['SS']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        _selectedCategory == 'SS' ? FontWeight.bold : FontWeight.normal,
                        color: _selectedCategory == 'SS' ? Colors.blue : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 중앙 박스 (푸른색 박스 80x80) + AnimatedPositioned로 움직이는 흰 원 (30x30)
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFC5D5FF),
                borderRadius: BorderRadius.circular(10),

              ),
              child: Stack(
                children: [
                  // 상단에만 inner shadow 효과를 주기 위한 그라데이션 오버레이
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 50, // 그림자 높이: 필요에 따라 조정하세요.
                    child: Container(
                      decoration: BoxDecoration(
                        // 상단 모서리와의 일치를 위해 borderRadius 적용
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25), // 그림자 색상 및 투명도 조절
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // AnimatedPositioned로 offset.y / offset.x 변경 시 애니메이션
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: offset.dx,
                    top: offset.dy,
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

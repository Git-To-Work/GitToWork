import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String currentCategory;

  const CategorySelector({super.key, required this.currentCategory});

  double _calcCircleLeft(String category) {
    switch (category) {
      case 'CS':
        return 0;
      case 'FI':
        return 10;
      case 'CL':
        return 20;
      case 'SS':
        return 30;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: const Text('CS', style: TextStyle(fontSize: 14)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(width: 16),
                Text('인성면접', style: TextStyle(fontSize: 14)),
                SizedBox(width: 16),
                Text('자소서', style: TextStyle(fontSize: 14)),
                SizedBox(width: 16),
                Text('기술 스택', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
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

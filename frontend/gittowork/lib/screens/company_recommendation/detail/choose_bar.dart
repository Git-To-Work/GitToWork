import 'package:flutter/material.dart';

class ChooseView extends StatelessWidget {
  const ChooseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // 내용만큼 높이
      children: [
        SizedBox(
          height: 60,
          child: Row(
            children: [
              // 좋아요 버튼
              Expanded(
                child: Material(
                  color: const Color(0xFFF0F5FF),
                  child: InkWell(
                    onTap: () {},
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.thumb_up_alt_outlined, color: Color(0xFF1976D2)),
                          SizedBox(width: 8),
                          Text(
                            '좋아요',
                            style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 차단 버튼
              Expanded(
                child: Material(
                  color: const Color(0xFFFFF2F0),
                  child: InkWell(
                    onTap: () {},
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.block, color: Color(0xFFD32F2F)),
                          SizedBox(width: 8),
                          Text(
                            '차단',
                            style: TextStyle(
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40), // 하단 여백 추가
      ],
    );
  }
}

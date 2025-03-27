import 'package:flutter/material.dart';

class MyPageButtonRow extends StatelessWidget {
  const MyPageButtonRow({super.key});

  @override
  Widget build(BuildContext context) {
    const iconColor = Colors.white; // 검정 배경 위에서 잘 보이도록

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: const [
            Icon(Icons.bookmark_border, color: iconColor),
            SizedBox(height: 4),
            Text('스크랩', style: TextStyle(color: iconColor)),
          ],
        ),
        Column(
          children: const [
            Icon(Icons.favorite_border, color: iconColor),
            SizedBox(height: 4),
            Text('좋아요', style: TextStyle(color: iconColor)),
          ],
        ),
        Column(
          children: const [
            Icon(Icons.history, color: iconColor),
            SizedBox(height: 4),
            Text('최근 본', style: TextStyle(color: iconColor)),
          ],
        ),
      ],
    );
  }
}

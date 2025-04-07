// my_page_button_row.dart
import 'package:flutter/material.dart';

import '../company_interaction_screen.dart';

class MyPageButtonRow extends StatelessWidget {
  const MyPageButtonRow({super.key});

  @override
  Widget build(BuildContext context) {
    const iconColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: const Color(0xFFAFAFAF),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // 스크랩 버튼
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScrapCompanyScreen()),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.bookmark_border, color: iconColor),
                    SizedBox(height: 4),
                    Text('스크랩', style: TextStyle(color: iconColor, fontSize: 15)),
                  ],
                ),
              ),
            ),
            Container(
              width: 1,
              color: const Color(0xFFAFAFAF),
              margin: const EdgeInsets.symmetric(vertical: 10),
            ),
            // 좋아요 버튼
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LikedCompanyScreen()),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.favorite_border, color: iconColor),
                    SizedBox(height: 4),
                    Text('좋아요', style: TextStyle(color: iconColor, fontSize: 15)),
                  ],
                ),
              ),
            ),
            Container(
              width: 1,
              color: const Color(0xFFAFAFAF),
              margin: const EdgeInsets.symmetric(vertical: 10),
            ),
            // 최근 본 버튼
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecentCompanyScreen()),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.history, color: iconColor),
                    SizedBox(height: 4),
                    Text('최근 본', style: TextStyle(color: iconColor, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

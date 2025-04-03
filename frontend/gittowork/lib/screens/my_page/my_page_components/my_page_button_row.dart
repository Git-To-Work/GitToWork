import 'package:flutter/material.dart';

class MyPageButtonRow extends StatelessWidget {
  const MyPageButtonRow({super.key});

  @override
  Widget build(BuildContext context) {
    const iconColor = Colors.white; // 검정 배경 위에서 잘 보이도록 흰색

    // 바깥쪽에 padding을 부여하여, 내부 콘텐츠 폭은 그대로 두되
    // 좌우에 일정 여백을 가지도록 함
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        height: 80, // 원하는 높이 지정
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: const Color(0xFFAFAFAF), // Stroke 색상
            width: 1,                       // Stroke 두께
          ),
          borderRadius: BorderRadius.circular(20), // 모서리 반경
        ),
        child: Row(
          children: [
            // 첫 번째 버튼
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.bookmark_border, color: iconColor),
                  SizedBox(height: 4),
                  Text('스크랩', style: TextStyle(color: iconColor, fontSize:15)),
                ],
              ),
            ),
            // 첫 번째와 두 번째 버튼 사이 구분선
            Container(
              width: 1,
              color: const Color(0xFFAFAFAF),
              margin: const EdgeInsets.symmetric(vertical: 10),
            ),
            // 두 번째 버튼
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.favorite_border, color: iconColor),
                  SizedBox(height: 4),
                  Text('좋아요', style: TextStyle(color: iconColor, fontSize:15)),
                ],
              ),
            ),
            // 두 번째와 세 번째 버튼 사이 구분선
            Container(
              width: 1,
              color: const Color(0xFFAFAFAF),
              margin: const EdgeInsets.symmetric(vertical: 10),
            ),
            // 세 번째 버튼
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history, color: iconColor),
                  SizedBox(height: 4),
                  Text('최근 본', style: TextStyle(color: iconColor, fontSize:15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

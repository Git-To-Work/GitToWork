import 'package:flutter/material.dart';

class SearchBarWithFilters extends StatelessWidget {
  const SearchBarWithFilters({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 검색창
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, size: 28), // 아이콘 크기 키움
            hintText: "검색",
            hintStyle: const TextStyle(fontSize: 18), // 힌트 텍스트 크기 증가
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20), // 입력창 크기 증가
          ),
          style: const TextStyle(fontSize: 18), // 입력 텍스트 크기 증가
        ),
        const SizedBox(height: 16), // 간격 증가

        // 🔹 가로 스크롤 가능한 필터 버튼
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterButton("My Repo"),
              _buildFilterButton("기술스택"),
              _buildFilterButton("직무"),
              _buildFilterButton("경력"),
              _buildFilterButton("지역"),
            ],
          ),
        ),
      ],
    );
  }

  // 🔹 기본 필터 버튼 스타일 (아이콘 추가)
  Widget _buildFilterButton(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton(
        onPressed: () {}, // 기능 없음
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 버튼 크기 증가
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          side: const BorderSide(color: Color(0xFF6C6C6C)), // 🔹 외곽선 색 변경
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // 버튼 크기를 내용에 맞춤
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            const SizedBox(width: 6), // 텍스트와 아이콘 사이 간격
            Image.asset(
              'assets/images/Drop_Down.png', // 아이콘 경로
              width: 16, // 아이콘 크기 조정
              height: 16,
            ),
          ],
        ),
      ),
    );
  }
}

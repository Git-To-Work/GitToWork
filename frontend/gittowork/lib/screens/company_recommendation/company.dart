import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar.dart';
import 'package:gittowork/screens/company_recommendation/search.dart'; // 🔹 search.dart import

class CompanyScreen extends StatelessWidget {
  const CompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 16.0), // 🔹 좌우 15, 상하 16 설정
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchBarWithFilters(), // 🔹 검색창 + 필터 UI 추가
          ],
        ),
      ),
    );
  }
}

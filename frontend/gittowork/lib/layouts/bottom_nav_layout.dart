import 'package:flutter/material.dart';
import 'package:gittowork/widgets/bottom_nav_bar.dart';
import 'package:gittowork/screens/github_analysis/github.dart';
import 'package:gittowork/screens/company_recommendation/company.dart';
import 'package:gittowork/screens/cover_letter/coverLetter.dart';
import 'package:gittowork/screens/entertainment/entertainment.dart';

import '../screens/my_page/my_page_screen.dart';

class BottomNavLayout extends StatefulWidget {
  const BottomNavLayout({super.key});

  @override
  State<BottomNavLayout> createState() => _BottomNavLayoutState();
}

class _BottomNavLayoutState extends State<BottomNavLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    GitHubScreen(),      // 메인 화면
    CompanyScreen(),     // 기업 화면
    CoverLetterScreen(), // 자소서 화면
    EntertainmentScreen(), // 엔터테이먼트 화면
    MyPageScreen(),      // 마이페이지 화면
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

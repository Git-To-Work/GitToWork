import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar.dart'; // 실제 경로에 맞게 수정
import 'package:gittowork/widgets/bottom_nav_bar.dart'; // 아래 업데이트된 CustomBottomNavBar 사용
import 'package:gittowork/screens/github_analysis/github.dart';
import 'package:gittowork/screens/company_recommendation/company.dart';

class AppBarBottomNavLayout extends StatefulWidget {
  const AppBarBottomNavLayout({super.key});

  @override
  State<AppBarBottomNavLayout> createState() => _AppBarBottomNavLayoutState();
}

class _AppBarBottomNavLayoutState extends State<AppBarBottomNavLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    GitHubScreen(),   // 메인 화면
    CompanyScreen(),  // 기업 화면
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

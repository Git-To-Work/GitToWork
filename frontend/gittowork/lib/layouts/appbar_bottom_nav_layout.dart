import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/widgets/bottom_nav_bar.dart';
import 'package:gittowork/screens/github_analysis/github.dart';
import 'package:gittowork/screens/company_recommendation/company.dart';
import 'package:gittowork/screens/cover_letter/cover_letter_screen.dart';
import 'package:gittowork/screens/entertainment/entertainment.dart';
import '../screens/my_page/my_page_screen.dart';
import 'package:gittowork/providers/company_provider.dart';

class AppBarBottomNavLayout extends StatefulWidget {
  const AppBarBottomNavLayout({super.key});

  @override
  State<AppBarBottomNavLayout> createState() => _AppBarBottomNavLayoutState();
}

class _AppBarBottomNavLayoutState extends State<AppBarBottomNavLayout> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  final List<Widget> _screens = const [
    GitHubScreen(),         // 메인 화면
    CompanyScreen(),        // 기업 화면
    CoverLetterScreen(),    // 자소서 화면
    EntertainmentScreen(),  // 엔터테인먼트 화면
    MyPageScreen(),         // 마이페이지 화면
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 버튼 클릭 시 페이지 애니메이션 효과와 함께 전환
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // 항상 AppBar 없음
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            Provider.of<CompanyProvider>(context, listen: false)
                .loadCompaniesFromApi(
              selectedRepositoriesId: "1",
              techStacks: [],
              field: [],
              career: "",
              location: "",
              keword: "",
              page: "1",
              size: "10",
            )
                .then((_) {
              Provider.of<CompanyProvider>(context, listen: false).companies;
            }).catchError((error) {
              debugPrint("API Error: $error");
            });
          }
        },
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}

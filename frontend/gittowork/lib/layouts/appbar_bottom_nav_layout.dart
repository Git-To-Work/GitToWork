import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gittowork/widgets/bottom_nav_bar.dart';
import 'package:gittowork/screens/github_analysis/github.dart';
import 'package:gittowork/screens/company_recommendation/company.dart';
import 'package:gittowork/screens/cover_letter/cover_letter_screen.dart';
import 'package:gittowork/screens/entertainment/entertainment.dart';
import '../screens/my_page/my_page_screen.dart';
import '../services/github_api.dart';


class AppBarBottomNavLayoutWithIndex extends StatelessWidget {
  final int initialIndex;
  const AppBarBottomNavLayoutWithIndex({super.key, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return AppBarBottomNavLayout(initialIndex: initialIndex);
  }
}

class AppBarBottomNavLayout extends StatefulWidget {
  final int initialIndex;
  const AppBarBottomNavLayout({super.key, this.initialIndex = 0});

  @override
  State<AppBarBottomNavLayout> createState() => _AppBarBottomNavLayoutState();
}


class _AppBarBottomNavLayoutState extends State<AppBarBottomNavLayout> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(); // ✅ 추가
  late int _selectedIndex;
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
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    _loadGitHubData(); // ✅ 초기화 시 실행
  }

  Future<void> _loadGitHubData() async {
    final selectedRepoId = await _secureStorage.read(key: 'selected_repo_id');

    if (selectedRepoId == null || selectedRepoId.isEmpty) {
      debugPrint("⚠ 저장된 selected_repo_id가 없습니다.");
      return;
    }

    debugPrint("✅ 저장된 selected_repo_id: $selectedRepoId");

    try {
      debugPrint("분석 데이터 실행");
      final result = await GitHubApi.fetchGithubAnalysis(
        context: context,
        selectedRepositoryId: selectedRepoId,
      );
      if (result['analyzing'] == true) {
        debugPrint("⌛ 아직 분석 중입니다.");
      } else {
        debugPrint("✅ 분석 결과 저장 완료");
      }
    } catch (e) {
      debugPrint("❌ 분석 데이터 불러오기 실패: $e");
    }
  }


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
      appBar: null,
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
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

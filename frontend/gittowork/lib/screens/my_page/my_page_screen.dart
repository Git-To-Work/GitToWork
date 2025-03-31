import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 경로는 실제 프로젝트 구조에 맞춰 조정
import '../../../providers/auth_provider.dart';
import '../../../models/user_profile.dart';

// 나머지 컴포넌트 위젯들
import 'my_page_components/my_page_header.dart';
import 'my_page_components/my_page_button_row.dart';
import 'my_page_components/my_page_list.dart';
import 'my_page_components/my_page_footer.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authProvider = context.read<AuthProvider>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await authProvider.fetchUserProfile();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      setState(() {
        _errorMessage = '사용자 정보를 불러오는 데 실패했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final UserProfile? userProfile = authProvider.userProfile;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('재시도'),
            ),
          ],
        ),
      )
          : userProfile == null
          ? const Center(child: Text('로그인이 필요합니다.'))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) 상단 검정 배경 영역
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2C2C2C), Color(0xFF464646)
                  ]
                )),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 90),
                  MyPageHeader(userProfile: userProfile),
                  const SizedBox(height: 30),
                  const MyPageButtonRow(),
                  const SizedBox(height: 30),
                ],
              ),
            ),

            // 2) 리스트 영역
            MyPageList(userProfile: userProfile,),

            // 3) 하단 로그아웃 / 회원탈퇴
            MyPageFooter(),
          ],
        ),
      ),
    );
  }
}

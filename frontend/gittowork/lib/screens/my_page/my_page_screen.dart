import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../models/user_profile.dart';
import '../../../models/interest_field.dart';
import '../../../services/user_api.dart';

// 나머지 컴포넌트 위젯들
import 'my_page_components/my_page_header.dart';
import 'my_page_components/my_page_button_row.dart';
import 'my_page_components/my_page_list.dart';
import 'my_page_components/my_page_footer.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => MyPageScreenState();
}

class MyPageScreenState extends State<MyPageScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? _userProfile;
  InterestField? _interestField;

  @override
  void initState() {
    super.initState();
    _loadProfileAndInterest();
  }

  Future<void> _loadProfileAndInterest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetchedProfile = await UserApi.fetchUserProfile();
      final fetchedInterest = await UserApi.fetchUserInterestField();

      // 2) 화면(State)에서 직접 관리
      _userProfile = fetchedProfile;
      _interestField = fetchedInterest;
    } catch (e) {
      debugPrint('Error fetching user profile or interest: $e');
      setState(() {
        _errorMessage = '사용자 정보를 불러오는 데 실패했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> loadProfileAgain() async {
    // 프로필 다시 불러오는 로직
    // e.g. await authProvider.fetchUserProfile() or similar
    await _loadProfileAndInterest(); // 혹은 로직 직접 작성
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final UserProfile? userProfile = _userProfile;

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
              onPressed: _loadProfileAndInterest,
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
                  const SizedBox(height: 50),
                  MyPageHeader(userProfile: userProfile),
                  const SizedBox(height: 30),
                  const MyPageButtonRow(),
                  const SizedBox(height: 30),
                ],
              ),
            ),

            // 2) 리스트 영역
            MyPageList(
              userProfile: _userProfile!,
              interestField: _interestField!,
            ),
            // 3) 하단 로그아웃 / 회원탈퇴
            MyPageFooter(),
          ],
        ),
      ),
    );
  }
}

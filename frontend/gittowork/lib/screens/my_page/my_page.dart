// my_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_bar.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPage> {
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
    final userProfile = authProvider.userProfile;

    return Scaffold(
      // 이미 커스텀 AppBar, BottomNavigationBar가 있다고 가정
      appBar: CustomAppBar(),
      // bottomNavigationBar: CustomBottomNavigationBar(),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Column(
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('재시도'),
              ),
            ],
          )
              : userProfile == null
              ? const Text('로그인이 필요합니다.')
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 인사 문구 (nickname or name 사용)
              Text(
                '${userProfile.nickname}님\n.gittowork에 오신걸 환영합니다',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 스크랩, 좋아요, 최근 본 버튼 3개 가로 배치
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: const [
                      Icon(Icons.bookmark_border),
                      SizedBox(height: 4),
                      Text('스크랩'),
                    ],
                  ),
                  Column(
                    children: const [
                      Icon(Icons.favorite_border),
                      SizedBox(height: 4),
                      Text('좋아요'),
                    ],
                  ),
                  Column(
                    children: const [
                      Icon(Icons.history),
                      SizedBox(height: 4),
                      Text('최근 본'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 나의 정보 관리, 내가 차단한 기업, 서비스 이용 약관 버튼 3개 세로 배치
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: ListTile(
                  title: const Text('나의 정보 관리'),
                  onTap: () {
                    // TODO: Implement navigation or action
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: ListTile(
                  title: const Text('내가 차단한 기업'),
                  onTap: () {
                    // TODO: Implement navigation or action
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: ListTile(
                  title: const Text('서비스 이용 약관'),
                  onTap: () {
                    // TODO: Implement navigation or action
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 로그아웃 | 회원 탈퇴
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      authProvider.logout();
                      // TODO: 로그아웃 후 이동 처리(로그인 화면 등)
                    },
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const Text('|', style: TextStyle(color: Colors.black)),
                  TextButton(
                    onPressed: () {
                      // TODO: 회원 탈퇴 처리
                    },
                    child: const Text(
                      '회원 탈퇴',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

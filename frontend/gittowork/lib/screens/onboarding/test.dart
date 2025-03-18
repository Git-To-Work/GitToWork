import 'package:flutter/material.dart';
// 상대경로: 현재 파일이 lib/screens/onboarding/ 폴더에 있으므로
// 두 단계 상위(../..)로 올라가 layouts 폴더에 접근
import '../../../layouts/appbar_bottom_nav_layout.dart';
import '../signup/github_oauth_login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '온보딩 화면',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 다음 버튼 클릭 시 appbar_bottom_nav_layout.dart 화면으로 이동
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => GithubOAuthLoginScreen(),
                    //builder: (context) => const AppBarBottomNavLayout(),
                  ),
                );
              },
              child: const Text('다음'),
            ),
          ],
        ),
      ),
    );
  }
}

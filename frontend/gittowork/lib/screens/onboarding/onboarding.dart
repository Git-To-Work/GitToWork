import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../layouts/appbar_bottom_nav_layout.dart';
import '../../providers/auth_provider.dart';
import '../signup/signup_detail_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _storage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // GitHub 로그인 시도 및 백엔드 API 호출을 통해 SignInResponse를 받아옴
                final signInResponse = await authProvider.loginWithGitHub(context);
                debugPrint('signInResponse: $signInResponse');

                if (signInResponse != null) {
                  // 이미 회원인 경우 (privacyPolicyAgreed == true) → 메인 화면으로 이동
                  if (signInResponse.privacyPolicyAgreed) {
                    await _storage.write(
                      key: 'jwt_token',
                      value: signInResponse.accessToken,
                    );
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AppBarBottomNavLayout()),
                    );
                  } else {
                    // 신규 회원인 경우 → 가입 상세 정보 입력 화면으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignupDetailScreen(
                          nickname: signInResponse.nickname,
                          avatarUrl: signInResponse.avatarUrl,
                        ),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("로그인에 실패했습니다.")),
                  );
                }
              },
              child: const Text("GitHub으로 회원가입"),
            ),
            ElevatedButton(
              onPressed: () {
                // 테스트용 버튼(임의)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignupDetailScreen(
                    nickname: 'hansnam1105',
                    avatarUrl: '',
                  )),
                );
              },
              child: const Text("Go to Signup Detail"),
            ),
          ],
        ),
      ),
    );
  }
}

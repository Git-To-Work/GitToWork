import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../signup/signup_detail_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

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
                final signInResponse = await authProvider.loginWithGitHub(context); // BuildContext 전달
                debugPrint('signInResponse: $signInResponse');
                if (signInResponse != null) {
                  // 로그인 성공 시 SignupDetailScreen으로 이동 (필요한 데이터 전달)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SignupDetailScreen(
                        nickname: signInResponse.nickname,
                        avatarUrl: signInResponse.avatarUrl,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("로그인에 실패했습니다.")),
                  );
                }
              },
              child: const Text("Login with GitHub"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignupDetailScreen(nickname: 'hansnam1105', avatarUrl: '',)),
                );
              },
              child: Text("Go to Signup Detail"),
            ),
          ],
        ),
      ),
    );
  }
}
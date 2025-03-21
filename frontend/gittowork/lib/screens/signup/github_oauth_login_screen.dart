import 'package:flutter/material.dart';
import 'package:github_oauth/github_oauth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_bar.dart';
import 'signup_detail_screen.dart'; // 회원 상세 정보 입력 화면

class GithubOAuthLoginScreen extends StatelessWidget {
  GithubOAuthLoginScreen({super.key});

  // Github API 권한 계정 가져오기
  final GitHubSignIn githubSignIn = GitHubSignIn(
    clientId: dotenv.env['GITHUB_CLIENT_ID']!,
    clientSecret: dotenv.env['GITHUB_CLIENT_SECRET']!,
    redirectUrl: dotenv.env['GITHUB_REDIRECT_URL']!,
  );

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Center(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final result = await githubSignIn.signIn(context);

              if (result.status == GitHubSignInResultStatus.ok) {
                try {
                  // 여기서 result.token를 백엔드에 authorization code로 전송합니다.
                  final signInResponse = await ApiService().signInWithGitHub(result.token!);

                  // 백엔드에서 발급받은 JWT 토큰을 AuthProvider에 업데이트
                  authProvider.setAccessToken(signInResponse.accessToken);

                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('환영합니다, ${signInResponse.nickname}님!')),
                  );

                  navigator.pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => SignupDetailScreen(
                        nickname: signInResponse.nickname,
                        avatarUrl: signInResponse.avatarUrl,
                      ),
                    ),
                  );
                } catch (err) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('백엔드 인증 실패: $err')),
                  );
                }
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('GitHub 로그인 실패: ${result.errorMessage}')),
                );
              }
            },
            child: const Text('GitHub로 로그인'),
          ),
        ),
      ),
    );
  }
}

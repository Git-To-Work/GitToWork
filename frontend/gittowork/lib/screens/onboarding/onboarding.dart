import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../layouts/appbar_bottom_nav_layout.dart';
import '../../providers/auth_provider.dart';
import '../signup/signup_detail_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _storage = FlutterSecureStorage();
  bool _isLoading = false;

  Future<void> _handleGitHubSignup() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final signInResponse = await authProvider.loginWithGitHub(context);
    debugPrint('signInResponse: $signInResponse');

    if (!mounted) return;

    if (signInResponse != null) {
      await _storage.write(
        key: 'jwt_token',
        value: signInResponse.accessToken,
      );

      if (!mounted) return;

      if (signInResponse.privacyPolicyAgreed) {
        // 기존 회원: 홈 화면으로 이동 (기존 스택 제거)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppBarBottomNavLayout()),
              (route) => false,
        );
      } else {
        // 신규 회원: 가입 상세 화면으로 이동 (기존 스택 제거)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => SignupDetailScreen(
              nickname: signInResponse.nickname,
              avatarUrl: signInResponse.avatarUrl,
            ),
          ),
              (route) => false,
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  // 'assets/images/Duck.gif',
                  'assets/images/Duck.gif',
                  height: 240,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                const Text(
                  "GitHub 연동",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "GitHub 정보를 바탕으로 당신의 활동을 분석해요.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleGitHubSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    '로그인',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

// Provider
import 'package:provider/provider.dart';
import 'package:gittowork/providers/auth_provider.dart';
import 'package:gittowork/providers/github_analysis_provider.dart';
import 'package:gittowork/providers/company_provider.dart';
import 'package:gittowork/providers/company_detail_provider.dart';

// 레이아웃 파일 (스플래시로 쓸 화면)
import 'layouts/no_appbar_no_bottom_nav_layout.dart';
// 온보딩 화면 (3초 후 이동)
import 'screens/onboarding/onboarding.dart';
// 홈 화면 (자동 로그인 후 이동할 화면)
import 'layouts/appbar_bottom_nav_layout.dart';

// GlobalKey for ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'jwt_token'); // 저장된 JWT 토큰 읽어오기
  debugPrint('JWT 토큰: $token');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GitHubAnalysisProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => CompanyDetailProvider()),
      ],
      child: MyApp(initialToken: token),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? initialToken;
  const MyApp({super.key, this.initialToken});

  @override
  Widget build(BuildContext context) {
    // 빌드가 완료된 후에 토큰 설정하도록 예약 (여기서는 async gap 없이 사용)
    if (initialToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AuthProvider>(context, listen: false)
            .setAccessToken(initialToken!);
      });
    }
    return MaterialApp(
      title: 'Git To Work',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Pretendard',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w500),
          displayMedium: TextStyle(fontWeight: FontWeight.w500),
          displaySmall: TextStyle(fontWeight: FontWeight.w500),
          headlineLarge: TextStyle(fontWeight: FontWeight.w500),
          headlineMedium: TextStyle(fontWeight: FontWeight.w500),
          headlineSmall: TextStyle(fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontWeight: FontWeight.w500),
          titleMedium: TextStyle(fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(fontWeight: FontWeight.w500),
          bodySmall: TextStyle(fontWeight: FontWeight.w500),
          labelLarge: TextStyle(fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    // initState에서 Provider를 읽어 저장
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // 2초 스플래시 대기
    await Future.delayed(const Duration(seconds: 2));

    // 위젯이 여전히 마운트 되어 있는지 확인
    if (!mounted) return;

    // accessToken 존재 여부에 따라 화면 이동
    if (_authProvider.accessToken != null) {
      final success = await _authProvider.autoLoginWithToken();
      if (success) {
        try {
          await _authProvider.fetchUserProfile();
        } catch (e) {
          const SnackBar(content: Text("로그인에 실패했습니다."));
    }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppBarBottomNavLayout()),
        );
      } else {
        _authProvider.logout();
        final storage = FlutterSecureStorage();
        await storage.delete(key: 'jwt_token');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const NoAppBarNoBottomNavLayout();
  }
}

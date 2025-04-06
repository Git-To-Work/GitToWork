import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

// Provider
import 'package:provider/provider.dart';
import 'package:gittowork/providers/auth_provider.dart';
import 'package:gittowork/providers/github_analysis_provider.dart';
import 'package:gittowork/providers/quiz_provider.dart';
import 'package:gittowork/providers/company_provider.dart';
import 'package:gittowork/providers/company_detail_provider.dart';
import 'package:gittowork/providers/search_provider.dart';

// 레이아웃 파일 (스플래시로 쓸 화면)
import 'layouts/no_appbar_no_bottom_nav_layout.dart';
// 온보딩 화면 (3초 후 이동)
import 'screens/onboarding/onboarding.dart';
// 홈 화면 (자동 로그인 후 이동할 화면)
import 'layouts/appbar_bottom_nav_layout.dart';

import 'package:gittowork/services/company_api.dart';

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
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => CompanyDetailProvider()),
        ChangeNotifierProvider(create: (_) => SearchFilterProvider()),
      ],
      child: MyApp(initialToken: token),
    ),
  );
}

class MyApp extends StatefulWidget {
  final String? initialToken;
  const MyApp({super.key, this.initialToken});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.initialToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AuthProvider>(context, listen: false)
            .setAccessToken(widget.initialToken!);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  DateTime? _lastRequestTime;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      // 3분 제한 체크
      final now = DateTime.now();
      if (_lastRequestTime == null || now.difference(_lastRequestTime!).inMinutes >= 3) {
        _lastRequestTime = now;
        try {
          debugPrint("🛑 앱 종료되어도 requestAction 실행됨.");
          await CompanyApi.requestAction();
        } catch (e) {
          debugPrint("❌ requestAction 에러: $e");
        }
      } else {
        debugPrint("⏱ 3분 내 요청 제한으로 requestAction 실행하지 않음.");
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Git To Work',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Pretendard',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontWeight: FontWeight.w500),
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
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (_authProvider.accessToken != null) {
      final success = await _authProvider.autoLoginWithToken();
      if (!mounted) return;

      if (success) {
        try {
          await _authProvider.fetchUserProfile();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AppBarBottomNavLayout()),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("로그인에 실패했습니다.")),
            );
          }
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      } else {
        _authProvider.logout();
        final storage = FlutterSecureStorage();
        await storage.delete(key: 'jwt_token');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } else {
      if (!mounted) return;
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

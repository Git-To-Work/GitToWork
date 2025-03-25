import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gittowork/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// Provider
import 'package:gittowork/providers/github_analysis_provider.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GitHubAnalysisProvider()),
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
    // 저장된 토큰이 있으면 AuthProvider에 설정
    if (initialToken != null) {
      Provider.of<AuthProvider>(context, listen: false)
          .setAccessToken(initialToken!);
    }
    return MaterialApp(
      title: 'Git To Work',
      scaffoldMessengerKey: scaffoldMessengerKey, // GlobalKey 적용
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Pretendard', // 글로벌 폰트 지정
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
  @override
  void initState() {
    super.initState();
    // 3초 후에 자동 로그인 여부에 따라 화면 전환
    Timer(const Duration(seconds: 3), () {
      final authProvider =
      Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.accessToken != null) {
        // 토큰이 있으면 홈 화면으로 전환 (자동 로그인)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppBarBottomNavLayout()),
        );
      } else {
        // 토큰이 없으면 온보딩 화면으로 전환
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const NoAppBarNoBottomNavLayout();
  }
}

import 'package:flutter/material.dart';
import 'dart:async'; // Timer 사용을 위해 추가

// 레이아웃 파일 (스플래시로 쓸 화면)
import 'layouts/no_appbar_no_bottom_nav_layout.dart';
// 온보딩 화면 (3초 후 이동)
import 'screens/onboarding/test.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
    // 3초 후 온보딩 화면으로 전환
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 처음에 보여줄 스플래시 레이아웃
    return const NoAppBarNoBottomNavLayout();
  }
}

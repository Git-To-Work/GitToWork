import 'package:flutter/material.dart';

class NoAppBarNoBottomNavLayout extends StatelessWidget {
  const NoAppBarNoBottomNavLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2c2c2c),
      body: Center(
        child: Transform.translate(
          offset: const Offset(0, -10), // Y축으로 -50 픽셀 이동 (위로 이동)
          child: Image.asset(
            'assets/images/Big_Logo_Dark.png',
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

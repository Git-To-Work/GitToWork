import 'package:flutter/material.dart';

class NoAppBarNoBottomNavLayout extends StatelessWidget {
  const NoAppBarNoBottomNavLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2c2c2c),
      body: Center(
        child: Image.asset(
          'assets/images/Big_Logo_Dark.png',
          height: 200, // 필요에 따라 조절
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

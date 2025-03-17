import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      title: Image.asset(
        'assets/images/Big_Logo_White.png',
        height: 40,
        fit: BoxFit.contain,
      ),
    );
  }

  // AppBar 높이를 고정 80으로 설정
  @override
  Size get preferredSize => const Size.fromHeight(60);
}

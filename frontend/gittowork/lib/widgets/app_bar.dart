import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true, // 제목을 좌우 중앙 정렬
      title: Image.asset(
        'assets/images/Big_Logo_White.png',
        height: 40, // 필요에 따라 높이 조절
        fit: BoxFit.contain,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

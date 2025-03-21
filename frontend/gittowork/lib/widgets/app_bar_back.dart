import 'package:flutter/material.dart';

class CustomBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomBackAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false, // 기본 뒤로가기 버튼 제거
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      flexibleSpace: Stack(
        children: [
          Positioned(
            top: 60, // 상단에서 60픽셀 아래에 위치
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/Big_Logo_White.png',
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(130);
}

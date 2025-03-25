import 'package:flutter/material.dart';

class MyPageFooter extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onWithdraw;

  const MyPageFooter({
    super.key,
    required this.onLogout,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    // NavigationBar 바로 위에 위치한다고 가정
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: onLogout,
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.black),
            ),
          ),
          const Text('|', style: TextStyle(color: Colors.black)),
          TextButton(
            onPressed: onWithdraw,
            child: const Text(
              '회원 탈퇴',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

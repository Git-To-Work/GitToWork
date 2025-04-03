import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../services/auth_api.dart';

class MyPageFooter extends StatefulWidget {
  const MyPageFooter({super.key});

  // Create a public method to create the state.
  @override
  State<MyPageFooter> createState() => _MyPageFooterState();
}

class _MyPageFooterState extends State<MyPageFooter> {

  Future<void> _confirmLogout() async {
    final bool? confirmResult = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    if (confirmResult == true) {
      // 로그아웃 API 호출
      final success = await AuthApi.logout();

      // 위젯이 여전히 마운트되어 있는지 체크
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그아웃 되었습니다.')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그아웃 실패')),
        );
      }
    }
  }

  Future<void> _confirmWithdraw() async {
    final bool? confirmResult = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('회원 탈퇴'),
          content: const Text('정말 회원탈퇴 하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('탈퇴'),
            ),
          ],
        );
      },
    );

    if (confirmResult == true) {
      // 회원 탈퇴 API 호출
      final success = await AuthApi.withdrawAccount();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원탈퇴가 완료되었습니다.')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원탈퇴 실패')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // NavigationBar 바로 위에 위치한다고 가정
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: _confirmLogout,
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.black),
            ),
          ),
          const Text('|', style: TextStyle(color: Colors.black)),
          TextButton(
            onPressed: _confirmWithdraw,
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

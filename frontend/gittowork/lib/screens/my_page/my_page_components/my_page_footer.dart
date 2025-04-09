import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../services/auth_api.dart';
import '../../../widgets/alert_modal.dart';
import '../../../widgets/confirm_modal.dart';

class MyPageFooter extends StatefulWidget {
  const MyPageFooter({super.key});

  // Create a public method to create the state.
  @override
  State<MyPageFooter> createState() => _MyPageFooterState();
}

class _MyPageFooterState extends State<MyPageFooter> {

  Future<void> _confirmLogout() async {
    final bool? confirmResult = await showCustomConfirmDialog(
      context: context,
      content: '로그아웃하시겠습니까?',
      subText: '지금 로그아웃하면 앱에서 자동 로그인이 해제됩니다.',
    );

    if (confirmResult == true) {
      // 로그아웃 API 호출
      final success = await AuthApi.logout();

      if (!mounted) return;

      if (success) {
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
    final bool? confirmResult = await showCustomConfirmDialog(
      context: context,
      content: '회원 탈퇴하시겠습니까?',
      subText: '이 작업은 되돌릴 수 없습니다.',
    );

    if (confirmResult == true) {
      // 회원 탈퇴 API 호출
      final success = await AuthApi.withdrawAccount();

      if (!mounted) return;

      if (success) {
        await showCustomAlertDialog(
          context: context,
          content: '회원 탈퇴가 완료되었습니다.',
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

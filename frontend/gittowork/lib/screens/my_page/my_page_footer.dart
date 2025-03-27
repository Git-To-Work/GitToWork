import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class MyPageFooter extends StatelessWidget {
  const MyPageFooter({Key? key}) : super(key: key);

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirmResult = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    if (confirmResult == true) {
      // 실제 로그아웃 API 호출
      final success = await ApiService.logout();
      if (success) {
        // 로그아웃 성공 시 처리 (ex. 로그인 화면으로 이동)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그아웃 되었습니다.')),
        );
        // 예: Navigator.pushReplacementNamed(context, '/login');
      } else {
        // 로그아웃 실패 시 처리
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그아웃 실패')),
        );
      }
    }
  }

  Future<void> _confirmWithdraw(BuildContext context) async {
    final bool? confirmResult = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('회원 탈퇴'),
          content: const Text('정말 회원탈퇴 하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('탈퇴'),
            ),
          ],
        );
      },
    );

    if (confirmResult == true) {
      // 실제 회원탈퇴 API 호출
      final success = await ApiService.withdrawAccount();
      if (success) {
        // 탈퇴 성공 시 처리 (ex. 로그인 화면으로 이동)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원탈퇴가 완료되었습니다.')),
        );
        // 예: Navigator.pushReplacementNamed(context, '/login');
      } else {
        // 탈퇴 실패 시 처리
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
            onPressed: () => _confirmLogout(context),
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.black),
            ),
          ),
          const Text('|', style: TextStyle(color: Colors.black)),
          TextButton(
            onPressed: () => _confirmWithdraw(context),
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

import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';

class MyPageHeader extends StatelessWidget {
  final UserProfile userProfile;

  const MyPageHeader({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${userProfile.nickname}님\n.gittowork에 오신걸 환영합니다',
      style: const TextStyle(
        color: Colors.white, // 검정 배경에 맞춰 흰색
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

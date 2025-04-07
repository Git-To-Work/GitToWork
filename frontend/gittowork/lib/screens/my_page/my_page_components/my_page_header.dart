import 'package:flutter/material.dart';
import '../../../../models/user_profile.dart';

class MyPageHeader extends StatelessWidget {
  final UserProfile userProfile;

  const MyPageHeader({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${userProfile.name}님\n',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: '.',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: 'gittowork에 오신걸 환영합니다',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  }

import 'package:flutter/material.dart';
import 'package:gittowork/models/user_profile.dart';

class UserProfileCard extends StatelessWidget {
  final UserProfile userProfile;

  const UserProfileCard({Key? key, required this.userProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth / 3; // 화면 가로 폭의 1/3

    return Row(
      children: [
        SizedBox(
          width: imageSize,
          height: imageSize,
          child: CircleAvatar(
            radius: imageSize / 2,
            backgroundImage: userProfile.avatarUrl.isNotEmpty
                ? NetworkImage(userProfile.avatarUrl)
                : null,
            child: userProfile.avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 50, color: Colors.white70)
                : null,
          ),
        ),
        const SizedBox(width: 20),
        // 사용자 정보
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userProfile.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              userProfile.phone,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              '경력: ${userProfile.experience}년',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

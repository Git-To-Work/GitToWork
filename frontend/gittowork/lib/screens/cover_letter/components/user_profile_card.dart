import 'package:flutter/material.dart';
import 'package:gittowork/models/user_profile.dart';

class UserProfileCard extends StatelessWidget {
  final UserProfile userProfile;

  const UserProfileCard({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundImage: userProfile.avatarUrl.isNotEmpty
              ? NetworkImage(userProfile.avatarUrl)
              : null,
          child: userProfile.avatarUrl.isEmpty
              ? const Icon(Icons.person, size: 50, color: Colors.white70)
              : null,
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userProfile.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(userProfile.phone,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 5),
            Text('경력: ${userProfile.experience}년',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class AvatarNicknameSection extends StatelessWidget {
  final String avatarUrl;
  final String nickname;

  const AvatarNicknameSection({
    super.key,
    required this.avatarUrl,
    required this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(radius: 50, backgroundImage: NetworkImage(avatarUrl)),
        const SizedBox(height: 8),
        Text(nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class NotificationSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const NotificationSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('서비스 알림 수신 설정', style: TextStyle(fontSize: 16)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2C2C2C),
        ),
      ],
    );
  }
}

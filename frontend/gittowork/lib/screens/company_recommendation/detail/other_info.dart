import 'package:flutter/material.dart';

class WelfareSection extends StatelessWidget {
  const WelfareSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': '복리후생', 'content': '사내 카페, 헬스장, 통근버스'},
      {'title': '연금·보험', 'content': '국민연금, 고용보험, 산재보험, 건강보험'},
      {'title': '휴무·휴가·행사', 'content': '연차, 워크샵, 체육대회'},
    ];

    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              item['title']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                item['content']!,
                style: const TextStyle(color: Colors.black87),
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}

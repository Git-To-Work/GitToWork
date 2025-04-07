import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/lucky_provider.dart';

class LuckyResult extends StatelessWidget {
  const LuckyResult({super.key});

  @override
  Widget build(BuildContext context) {
    final lucky = Provider.of<LuckyProvider>(context);

    final categories = [
      _FortuneItem(
        title: '종합 운세',
        icon: Icons.stars,
        color: Colors.indigo,
        value: lucky.overall,
      ),
      _FortuneItem(
        title: '학업/일 운',
        icon: Icons.school,
        color: Colors.blue,
        value: lucky.study,
      ),
      _FortuneItem(
        title: '애정 운',
        icon: Icons.favorite,
        color: Colors.pink,
        value: lucky.love,
      ),
      _FortuneItem(
        title: '재물 운',
        icon: Icons.attach_money,
        color: Colors.green,
        value: lucky.wealth,
      ),
    ].where((item) => item.value.trim().isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lucky.fortuneDate.isNotEmpty
                    ? '${lucky.fortuneDate}의 운세'
                    : '오늘의 운세',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.share),
            ],
          ),
          const SizedBox(height: 12),

          // 내부 운세 카드들
          ...categories.map((item) => _buildFortuneCard(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildFortuneCard(_FortuneItem item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: item.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FortuneItem {
  final String title;
  final IconData icon;
  final Color color;
  final String value;

  _FortuneItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
  });
}

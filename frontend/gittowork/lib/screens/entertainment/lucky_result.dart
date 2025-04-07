import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // 🔹 공유 기능 import
import '../../providers/lucky_provider.dart';

class LuckyResult extends StatelessWidget {
  const LuckyResult({super.key});

  @override
  Widget build(BuildContext context) {
    final lucky = Provider.of<LuckyProvider>(context);

    final selected = lucky.selected;
    final Map<FortuneType, _FortuneItem> fortuneMap = {
      FortuneType.all: _FortuneItem(
        title: '종합 운세',
        icon: Icons.stars,
        color: Colors.indigo,
        value: lucky.overall,
      ),
      FortuneType.study: _FortuneItem(
        title: '학업/일 운',
        icon: Icons.school,
        color: Colors.blue,
        value: lucky.study,
      ),
      FortuneType.love: _FortuneItem(
        title: '애정 운',
        icon: Icons.favorite,
        color: Colors.pink,
        value: lucky.love,
      ),
      FortuneType.wealth: _FortuneItem(
        title: '재물 운',
        icon: Icons.attach_money,
        color: const Color(0xFFDAA520),
        value: lucky.wealth,
      ),
    };

    final currentItem = fortuneMap[selected];
    final hasResult = currentItem != null && currentItem.value.trim().isNotEmpty;

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
      child: lucky.loading
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀 + 공유 버튼
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
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
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    if (hasResult && currentItem != null) {
                      final text = '''
[${currentItem.title}]
${currentItem.value}

🔮 운세 날짜: ${lucky.fortuneDate}
''';
                      Share.share(text);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 운세 결과가 없을 때
          if (!hasResult)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                '운세를 조회해보세요 🔮',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ),

          // 운세 결과 카드
          if (hasResult) _buildFortuneCard(currentItem!),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, color: item.color),
              const SizedBox(width: 6),
              Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: item.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              item.value,
              style: const TextStyle(
                fontSize: 17,
                height: 1.6, // 줄간격 조절
              ),
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

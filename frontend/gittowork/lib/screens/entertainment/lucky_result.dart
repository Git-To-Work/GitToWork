import 'package:flutter/material.dart';

class LuckyResult extends StatelessWidget {
  const LuckyResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
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
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '운세',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.share),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '36년생 북쪽은 귀인이 오는 길목.\n'
                '48년생 명성과 지위가 다시 높아질 듯.\n'
                '60년생 성공한 삶은 실패를 두려워하지 않는 법.\n'
                '72년생 얻는 사람이 있으니 잃은 사람이 있을 수밖에.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

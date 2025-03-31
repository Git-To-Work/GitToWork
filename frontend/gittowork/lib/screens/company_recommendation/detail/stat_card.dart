import 'package:flutter/material.dart';

class StatCardSection extends StatelessWidget {
  const StatCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: StatCard(title: "임직원 수", value: "358명")),
            SizedBox(width: 16),
            Expanded(child: StatCard(title: "평균연봉", value: "5,384만원")),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: const [
            Expanded(child: StatCard(title: "신입평균", value: "3,414만원")),
            SizedBox(width: 16),
            Expanded(child: StatCard(title: "매출액", value: "783억원")),
          ],
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;

  const StatCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(40, 0, 0, 0),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
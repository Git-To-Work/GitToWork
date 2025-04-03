import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/providers/company_detail_provider.dart';

class StatCardSection extends StatelessWidget {
  const StatCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final company = Provider.of<CompanyDetailProvider>(context).companyDetail?['result'];

    if (company == null) {
      return const SizedBox(); // 또는 로딩 표시
    }

    // 숫자 포맷 (원/만원/억원)
    String formatSalary(int? salary) {
      if (salary == null) return '-';
      return '${salary.toString()}만원';
    }

    String formatSales(int? sales) {
      if (sales == null) return '-';
      return '${(sales / 100).round()}억원'; // 예: 32160 → 321.6억 → 반올림
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: StatCard(title: "임직원 수", value: "${company['head_count'] ?? '-'}명")),
            const SizedBox(width: 16),
            Expanded(child: StatCard(title: "평균연봉", value: formatSalary(company['all_avg_salary']))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: StatCard(title: "신입평균", value: formatSalary(company['newcomer_avg_salary']))),
            const SizedBox(width: 16),
            Expanded(child: StatCard(title: "매출액", value: formatSales(company['total_sales_value']))),
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/providers/company_detail_provider.dart';

class WelfareSection extends StatelessWidget {
  const WelfareSection({super.key});

  @override
  Widget build(BuildContext context) {
    final company = Provider.of<CompanyDetailProvider>(context).companyDetail?['result'];
    final benefits = company?['benefits'];
    final sections = benefits?['sections'] as List<dynamic>?;

    // 분류 초기화
    final Map<String, List<String>> grouped = {
      '복리후생': [],
      '연금·보험': [],
      '휴무·휴가·행사': [],
    };

    if (sections != null) {
      for (final section in sections) {
        final head = section['head'] ?? '';
        final List<dynamic> body = section['body'] ?? [];

        final target = (head == '연금·보험')
            ? '연금·보험'
            : (head == '휴무·휴가·행사')
            ? '휴무·휴가·행사'
            : '복리후생';

        if (grouped[target] != null) {
          grouped[target]!.addAll(body.map((e) => e.toString()));
        }

      }
    }

    return Column(
      children: grouped.entries.map((entry) {
        final title = entry.key;
        final items = entry.value;

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
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: items.isNotEmpty
                ? items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  "- $item",
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center, // 👉 가운데 정렬
                ),
              );
            }).toList()
                : [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  "정보가 없습니다.",
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center, // 👉 가운데 정렬
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}

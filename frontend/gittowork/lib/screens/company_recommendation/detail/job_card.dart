import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/providers/company_detail_provider.dart';

class JobCardSection extends StatelessWidget {
  const JobCardSection({super.key});

  String _formatDeadline(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '-';
    return "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final company = Provider.of<CompanyDetailProvider>(context).companyDetail?['result'];
    final List<dynamic>? jobNotices = company?['job_notices'];

    if (jobNotices == null || jobNotices.isEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 160),
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [ // ✅ 그림자 효과 추가
            BoxShadow(
              color: Color.fromARGB(40, 0, 0, 0),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "현재 채용 중인 공고가 없습니다.",
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Column(
      children: jobNotices.map((job) {
        final title = job['job_notice_title'] ?? '';
        final List<dynamic> techStacks = job['tech_stacks'] ?? [];
        final minCareer = job['min_career'] ?? 0;
        final careerText = minCareer == 0
            ? '신입'
            : '경력 ${minCareer}년 이상';
        final location = job['location'] ?? '-';
        final deadline = _formatDeadline(job['deadline_dttm'] ?? '');


        return Container(
          constraints: const BoxConstraints(minHeight: 150),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(40, 0, 0, 0),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: techStacks.map<Widget>((stack) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      stack.toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$careerText | $location',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '~${deadline}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}

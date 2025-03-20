import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/providers/github_analysis_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GitHubAnalysisProvider>(
      builder: (context, provider, child) {
        final totalStars = provider.testData.isNotEmpty ? provider.testData[0] : 342;
        final totalCommits = provider.testData.length > 1 ? provider.testData[1] : 1247;
        final totalPRs = provider.testData.length > 2 ? provider.testData[2] : 86;
        final totalIssues = provider.testData.length > 3 ? provider.testData[3] : 124;
        final grade = 'C+';
        final gradePercent = 0.65;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(  // 👈 추가된 부분 (외곽선 효과)
              color: const Color(0xFFD6D6D6),
              width: 1,
            ),
            boxShadow: [ // 👈 추가된 부분 (그림자 효과)
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GitHub Stats',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Stars',
                              style: TextStyle(color: Colors.grey, fontSize: 16)),
                          Text('$totalStars',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          const Text('Total PRs',
                              style: TextStyle(color: Colors.grey, fontSize: 16)),
                          Text('$totalPRs',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Commits',
                              style: TextStyle(color: Colors.grey, fontSize: 16)),
                          Text('$totalCommits',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          const Text('Total Issues',
                              style: TextStyle(color: Colors.grey, fontSize: 16)),
                          Text('$totalIssues',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              CircularPercentIndicator(
                radius: 45,
                lineWidth: 6,
                percent: gradePercent,
                backgroundColor: Colors.grey.shade300,
                progressColor: Colors.black,
                circularStrokeCap: CircularStrokeCap.round,
                center: Text(
                  grade,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

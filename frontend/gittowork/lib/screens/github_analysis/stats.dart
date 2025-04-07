import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/providers/github_analysis_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    debugPrint('화면 너비: $screenWidth');
    return Consumer<GitHubAnalysisProvider>(
      builder: (context, provider, child) {
        final totalStars = provider.activityMetrics['totalStars'] ?? 342;
        final totalCommits = provider.activityMetrics['totalCommits'] ?? 1247;
        final totalPRs = provider.activityMetrics['totalPRs'] ?? 86;
        final totalIssues = provider.activityMetrics['totalIssues'] ?? 124;
        final grade = provider.overallScore;
        final gradePercent = provider.getGradePercent();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD6D6D6),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(64, 0, 0, 0),
                blurRadius: 4,
                offset: Offset(0, 4),
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
                          const Text('Total Stars', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          Text('$totalStars', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          const Text('Total PRs', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          Text('$totalPRs', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Commits', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          Text('$totalCommits', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          const Text('Total Issues', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          Text('$totalIssues', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              if (screenWidth > 400)
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

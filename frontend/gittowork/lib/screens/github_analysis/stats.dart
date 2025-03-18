import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/providers/github_analysis_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GitHubAnalysisProvider>(
      builder: (context, provider, child) {
        // Provider의 testData 리스트가 비어있지 않으면 첫번째 값을, 그렇지 않으면 0을 사용합니다.
        final int firstValue = provider.testData.isNotEmpty ? provider.testData[0] : 0;
        return Container(
          width: double.infinity,
          height: 200,
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Center(
            child: Text(
              'stats\n테스트 : $firstValue',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30),
            ),
          ),
        );
      },
    );
  }
}

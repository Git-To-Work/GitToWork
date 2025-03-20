import 'package:flutter/material.dart';
import 'stats.dart';
import 'language.dart';
import 'ai_analysis.dart';
import 'repo.dart'; // repo import 추가

class GitHubScreen extends StatelessWidget {
  const GitHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          children: const [
            RepoScreen(),     // Repo 영역
            StatsScreen(),    // 통계 영역
            LanguageScreen(), // 언어 영역
            AIAnalysisScreen(), // AI 분석 영역
          ],
        ),
      ),
    );
  }
}

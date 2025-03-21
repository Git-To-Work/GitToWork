import 'package:flutter/material.dart';
import 'package:gittowork/widgets/app_bar.dart';
import 'stats.dart';
import 'language.dart';
import 'ai_analysis.dart';
import 'repo.dart';

class GitHubScreen extends StatelessWidget {
  const GitHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(), // 사용자 정의 앱바 적용
      body: SingleChildScrollView(
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
      ),
    );
  }
}
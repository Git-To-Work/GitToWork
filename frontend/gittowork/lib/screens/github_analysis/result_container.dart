import 'package:flutter/material.dart';
import 'stats.dart';
import 'language.dart';
import 'ai_analysis.dart';

class ResultContainer extends StatelessWidget {
  const ResultContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        StatsScreen(),
        LanguageScreen(),
        AIAnalysisScreen(),
      ],
    );
  }
}

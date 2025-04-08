import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/widgets/app_bar.dart';
import 'fail.dart';
import 'repo.dart';
import 'analysing.dart';
import 'stats.dart';
import 'language.dart';
import 'ai_analysis.dart';
import '../../providers/github_analysis_provider.dart';

class GitHubScreen extends StatelessWidget {
  const GitHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: RepoScreen(),
          ),

          Expanded(
            child: Consumer<GitHubAnalysisProvider>(
              builder: (context, provider, _) {
                if (provider.status=='ANALYZING') {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: AnalysingScreen(),
                  );
                }
                else if (provider.status=='FAIL') {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: FailScreen(),
                  );
                }
                else {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        StatsScreen(),
                        LanguageScreen(),
                        AIAnalysisScreen(),
                      ],
                    ),
                  );
                }
              },
            ),
          ),

        ],
      ),
    );
  }
}

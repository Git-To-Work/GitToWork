import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gittowork/providers/github_analysis_provider.dart';

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  bool isAnalysisMode = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<GitHubAnalysisProvider>(
      builder: (context, provider, child) {
        final List<String> analysisSummary = provider.aiAnalysis['analysis_summary']?.cast<String>() ?? [];
        final List<String> improvementSuggestions = provider.aiAnalysis['improvement_suggestions']?.cast<String>() ?? [];

        final List<String> content = isAnalysisMode ? analysisSummary : improvementSuggestions;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD6D6D6), width: 1.0),
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "AI 분석",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Text("분석", style: TextStyle(fontSize: 16)),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isAnalysisMode,
                      activeTrackColor: const Color(0xFFBED7FF),
                      inactiveTrackColor: const Color(0xFFD9D9D9),
                      onChanged: (value) {
                        setState(() {
                          isAnalysisMode = value;
                        });
                      },
                    ),
                  ),
                  const Text("개선", style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              if (content.isEmpty)
                const Text(
                  "• 분석 데이터가 없습니다.",
                  style: TextStyle(fontSize: 16),
                )
              else
                ...content.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text("• $item", style: const TextStyle(fontSize: 16)),
                )),
            ],
          ),
        );
      },
    );
  }
}

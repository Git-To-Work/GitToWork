import 'package:flutter/material.dart';

class CoverLetterAiAnalysisBox extends StatelessWidget {
  final String? aiAnalysisResult;

  const CoverLetterAiAnalysisBox({
    Key? key,
    required this.aiAnalysisResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome), // 원하는 아이콘
              SizedBox(width: 8),
              Text(
                'AI 분석 결과',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (aiAnalysisResult == null)
            const Text('AI 분석 결과가 없습니다.')
          else
            Text(aiAnalysisResult!),
        ],
      ),
    );
  }
}

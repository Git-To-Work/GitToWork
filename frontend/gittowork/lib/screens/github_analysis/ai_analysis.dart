import 'package:flutter/material.dart';

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  // true면 "분석" 모드, false면 "개선" 모드
  bool isAnalysisMode = true;

  @override
  Widget build(BuildContext context) {
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
          // 상단: "AI 분석" 텍스트와 토글 및 양측 텍스트 ("분석" / "개선")
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
              // 왼쪽 "분석" 텍스트
              const Text(
                "분석",
                style: TextStyle(fontSize: 16),
              ),
              // 토글: 크기를 줄이기 위해 Transform.scale 사용
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
              // 오른쪽 "개선" 텍스트
              const Text(
                "개선",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 하단: "분석" 모드일 때와 "개선" 모드일 때 서로 다른 내용 표시
          if (isAnalysisMode)
            const Text(
              "• 최근 6개월 간 Python 코드를 집중적으로 작성하셨으니,\n  AI/ML 관련 프로젝트를 시도해보는 것도 좋겠습니다.\n\n"
                  "• 개선안: 모델 성능을 높이기 위해 추가적인 테스트와\n  최적화를 시도해보세요.",
              style: TextStyle(fontSize: 16),
            )
          else
            const Text(
              "• 개선안: 모델 성능을 높이기 위해 추가적인 테스트와\n  최적화를 시도해보세요.\n\n"
                  "• 최근 6개월 간 Python 코드를 집중적으로 작성하셨으니,\n  AI/ML 관련 프로젝트를 시도해보는 것도 좋겠습니다.",
              style: TextStyle(fontSize: 16),
            ),
        ],
      ),
    );
  }
}

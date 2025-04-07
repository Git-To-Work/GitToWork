import 'package:flutter/material.dart';
import '../../../services/quiz_api.dart';

class AnswerView extends StatelessWidget {
  final QuizQuestion quiz;
  final int? selectedIndex;
  final VoidCallback onNextQuestion;

  const AnswerView({
    super.key,
    required this.quiz,
    required this.selectedIndex,
    required this.onNextQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCorrect = selectedIndex == quiz.correctAnswerIndex;
    final String answerResult = isCorrect ? '정답입니다!' : '오답입니다.';
    final String correctChoice = quiz.choices[quiz.correctAnswerIndex];

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  answerResult,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '정답: $correctChoice',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                Text(
                  quiz.feedback,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    shadowColor: Colors.black,
                    elevation: 4,
                  ),
                  onPressed: onNextQuestion,
                  child: const Text(
                    '다음 질문',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        // SNS 공유 버튼
        Positioned(
          top: 20,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // SNS 공유 로직 구현
            },
          ),
        ),
      ],
    );
  }
}

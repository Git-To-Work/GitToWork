import 'package:flutter/material.dart';
import '../../../services/quiz_api.dart';
import 'choice_button.dart';

class QuestionView extends StatelessWidget {
  final QuizQuestion quiz;
  final Function(int) onSelectAnswer;

  const QuestionView({super.key, required this.quiz, required this.onSelectAnswer});

  Widget _buildTwoChoice(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ChoiceButton(
          label: 'A',
          onTap: () => onSelectAnswer(0),
        ),
        ChoiceButton(
          label: 'B',
          onTap: () => onSelectAnswer(1),
        ),
      ],
    );
  }

  Widget _buildOxChoice(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ChoiceButton(
          label: 'O',
          onTap: () => onSelectAnswer(0),
        ),
        ChoiceButton(
          label: 'X',
          onTap: () => onSelectAnswer(1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 문제 텍스트
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            quiz.questionText,
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),

        ),
        const SizedBox(height: 20),
        if (quiz.type == '2CHOICE')
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
               Text(
                'A : ${quiz.choices[0]}',
                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
               ),
              const SizedBox(height: 10),
              Text(
                'B : ${quiz.choices[1]}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildTwoChoice(context),
            ],
          ),

        if (quiz.type == 'OX') _buildOxChoice(context),
      ],
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gittowork/screens/entertainment/quiz/answer_view.dart';
import 'package:gittowork/screens/entertainment/quiz/category_selector.dart';
import 'package:gittowork/screens/entertainment/quiz/question_view.dart';

import '../../services/quiz_api.dart';
import '../../widgets/app_bar.dart';


class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  late Future<QuizQuestion> _quizFuture;
  int? _selectedIndex;
  bool _showAnswer = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _quizFuture = QuizApi.fetchQuiz();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: math.pi / 2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onSelectAnswer(int index) async {
    setState(() {
      _selectedIndex = index;
    });
    await _animationController.forward();
    setState(() {
      _showAnswer = true;
    });
  }

  void _onNextQuestion() async {
    setState(() {
      _showAnswer = false;
      _selectedIndex = null;
      _quizFuture = QuizApi.fetchQuiz();
    });
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: FutureBuilder<QuizQuestion>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('퀴즈 로드 실패: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('퀴즈 데이터가 없습니다.'));
          }

          final quiz = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // 분리된 카테고리 선택 위젯
                CategorySelector(currentCategory: quiz.category.toUpperCase()),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFD7D7D7)),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          offset: const Offset(0, 4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        final angle = _rotationAnimation.value;
                        return Transform(
                          alignment: FractionalOffset.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          child: _showAnswer
                              ? AnswerView(
                            quiz: quiz,
                            selectedIndex: _selectedIndex,
                            onNextQuestion: _onNextQuestion,
                          )
                              : QuestionView(
                            quiz: quiz,
                            onSelectAnswer: _onSelectAnswer,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

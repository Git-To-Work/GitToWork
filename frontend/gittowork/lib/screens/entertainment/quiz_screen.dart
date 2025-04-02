import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_provider.dart';
import 'package:gittowork/screens/entertainment/quiz/answer_view.dart';
import 'package:gittowork/screens/entertainment/quiz/category_selector.dart';
import 'package:gittowork/screens/entertainment/quiz/question_view.dart';
import '../../widgets/app_bar.dart';

// QuizScreen
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    final quizProvider = context.read<QuizProvider>();

    // 화면 첫 진입 시, 디폴트 카테고리("")라면 fetchQuiz("")로 호출
    // 필요 없다면 주석 처리
    quizProvider.fetchQuiz("");

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // 0에서 π(180도)까지 회전
    _rotationAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 답안 선택 시
  void _onSelectAnswer(int index) async {
    setState(() {
      _selectedIndex = index;
    });
    await _animationController.forward();
    debugPrint("AnswerView가 표시되었습니다.");
  }

  // 다음 질문
  void _onNextQuestion() async {
    // Provider로부터 새 퀴즈 로딩
    await context.read<QuizProvider>().loadNextQuiz();
    // 다시 QuestionView가 보이도록 회전 초기화
    _animationController.reset();
    setState(() {
      _selectedIndex = null;
    });
  }

  // 카테고리 변경 시
  void _onCategoryChanged(String newCategory) {
    // 카테고리 바꾸고 새 퀴즈 받아오기
    context.read<QuizProvider>().fetchQuiz(newCategory);
    // QuestionView 상태로 초기화
    _animationController.reset();
    setState(() {
      _selectedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Consumer 혹은 context.select를 사용해 QuizProvider 상태를 가져옴
    return Scaffold(
      appBar: CustomAppBar(),
      // AnimatedSwitcher로 퀴즈 데이터가 바뀔 때 화면 전환을 부드럽게
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          // child: 현재 QuizProvider 상태에 따라 UI를 결정
          Widget childWidget;

          if (quizProvider.isLoading) {
            childWidget = const Center(child: CircularProgressIndicator());
          } else if (quizProvider.errorMessage.isNotEmpty) {
            childWidget = Center(child: Text(quizProvider.errorMessage));
          } else if (quizProvider.quiz == null) {
            childWidget = const Center(child: Text('퀴즈 데이터가 없습니다.'));
          } else {
            // 정상적으로 퀴즈가 로딩된 경우
            final quiz = quizProvider.quiz!;
            childWidget = Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 50),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        '개발자 퀴즈',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // CategorySelector(Provider에서 받은 카테고리를 넘겨주기)
                  // category_selector.dart를 StatefulWidget으로 바꾸고,
                  // initialCategory: quizProvider.currentCategory
                  // 형태로 넘기면 중앙 원 애니메이션도 쉽게 연동 가능
                  CategorySelector(
                    initialCategory: quiz.category,
                    onCategoryChanged: _onCategoryChanged,
                  ),
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
                          final bool showBack = angle > math.pi / 2;

                          Widget currentChild;
                          if (showBack) {
                            // 뒤집힌 뒷면 (AnswerView)
                            currentChild = Transform(
                              alignment: FractionalOffset.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: AnswerView(
                                quiz: quiz,
                                selectedIndex: _selectedIndex,
                                onNextQuestion: _onNextQuestion,
                              ),
                            );
                          } else {
                            // 정면 (QuestionView)
                            currentChild = QuestionView(
                              quiz: quiz,
                              onSelectAnswer: _onSelectAnswer,
                            );
                          }

                          return Transform(
                            alignment: FractionalOffset.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            child: currentChild,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // AnimatedSwitcher로 childWidget 전환 애니메이션 (페이드 효과)
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: childWidget,
          );
        },
      ),
    );
  }
}

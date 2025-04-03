import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_provider.dart';
import 'package:gittowork/screens/entertainment/quiz/answer_view.dart';
import 'package:gittowork/screens/entertainment/quiz/category_selector.dart';
import 'package:gittowork/screens/entertainment/quiz/question_view.dart';
import '../../widgets/app_bar.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _animController;
  late Animation<double> _rotationAnimation;
  // 현재 선택된 카테고리 (Provider에 저장해도 되고, 여기서 관리해도 됩니다)
  String _currentCategory = "";

  @override
  void initState() {
    super.initState();
    final quizProvider = context.read<QuizProvider>();

    // 첫 진입 시 카테고리가 없다면 ""로 로드
    _currentCategory = quizProvider.currentQuiz?.category ?? "";
    // 만약 currentQuiz가 없으면 첫 로드
    if (quizProvider.currentQuiz == null) {
      quizProvider.loadQuiz(_currentCategory);
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // 0~π로 회전 (카드 뒤집기)
    _rotationAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // 사용자가 답을 선택
  void _onSelectAnswer(int index) async {
    setState(() {
      _selectedIndex = index;
    });
    await _animController.forward();
    debugPrint("AnswerView가 표시되었습니다.");
  }

  // 다음 문제 버튼
  Future<void> _onNextQuestion() async {
    // 여기서는 category 바꾸지 않았으니 동일한 카테고리로 새 문제 로드
    final quizProvider = context.read<QuizProvider>();
    await quizProvider.loadQuiz(_currentCategory);
    // 로딩 완료 -> 지금은 _cachedQuiz에 저장된 상태

    // 애니메이션 초기화
    _animController.reset();
    setState(() {
      _selectedIndex = null;
    });

    // (중요) 현재 문제를 새 문제로 교체
    quizProvider.commitCachedQuiz();
  }

  // 카테고리 변경 시
  Future<void> _onCategoryChanged(String newCategory) async {
    // 선택된 카테고리 변경
    _currentCategory = newCategory;

    final quizProvider = context.read<QuizProvider>();
    // 새 카테고리 퀴즈를 불러온다 (기존 문제 계속 유지)
    await quizProvider.loadQuiz(newCategory);
    // 애니메이션 초기화
    _animController.reset();
    setState(() {
      _selectedIndex = null;
    });

    // 이제 로딩 끝났으면 _cachedQuiz가 있을 것이므로 화면 전환
    quizProvider.commitCachedQuiz();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          // error 처리
          if (quizProvider.errorMessage.isNotEmpty) {
            return Center(child: Text(quizProvider.errorMessage));
          }

          // 현재 퀴즈가 없으면 로딩 중인지 확인 -> 로딩이면 표시, 아니면 "없음"
          if (quizProvider.currentQuiz == null) {
            if (quizProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return const Center(child: Text("퀴즈 데이터가 없습니다."));
            }
          }

          final quiz = quizProvider.currentQuiz!;
          return Padding(
            padding: const EdgeInsets.fromLTRB(30, 0, 30, 50),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        '개발자 퀴즈',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // 오른쪽 아이콘 버튼과 균형을 맞추기 위해 동일한 크기의 빈 공간
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                // CategorySelector (현재 카테고리 넘겨주기)
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
        },
      ),
    );
  }
}

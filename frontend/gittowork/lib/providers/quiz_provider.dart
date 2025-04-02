import 'package:flutter/material.dart';
import '../../services/quiz_api.dart';

class QuizProvider extends ChangeNotifier {
  bool isLoading = false;       // 로딩 중인지 여부
  QuizQuestion? quiz;          // 현재 퀴즈 데이터
  String errorMessage = "";     // 에러 메시지 (없으면 "")

  String currentCategory = "";  // 현재 선택된 카테고리

  // 카테고리에 맞는 새 퀴즈 가져오기
  Future<void> fetchQuiz(String category) async {
    // 로딩 시작
    isLoading = true;
    notifyListeners();

    try {
      final newQuiz = await QuizApi.fetchQuiz(category);
      quiz = newQuiz;
      currentCategory = category;
      errorMessage = "";
    } catch (e) {
      errorMessage = "퀴즈 로드 실패: $e";
      quiz = null;
    }

    // 로딩 끝
    isLoading = false;
    notifyListeners();
  }

  // 이미 currentCategory가 있으니 재요청할 때
  Future<void> loadNextQuiz() async {
    if (currentCategory.isEmpty) return;
    await fetchQuiz(currentCategory);
  }
}

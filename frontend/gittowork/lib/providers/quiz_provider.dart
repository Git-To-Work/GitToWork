import 'package:flutter/material.dart';
import '../../services/quiz_api.dart';

class QuizProvider extends ChangeNotifier {
  QuizQuestion? _currentQuiz; // 현재 화면에 표시 중인 퀴즈
  QuizQuestion? get currentQuiz => _currentQuiz;

  QuizQuestion? _cachedQuiz;  // 새로 로딩된 다음 퀴즈 (아직 화면에 안 보이는 상태)
  QuizQuestion? get cachedQuiz => _cachedQuiz;

  bool isLoading = false;     // 지금 새 퀴즈를 로딩 중인지
  String errorMessage = "";

  // 최초/다음 퀴즈 로딩
  Future<void> loadQuiz(String category) async {
    isLoading = true;
    notifyListeners();
    try {
      final fetched = await QuizApi.fetchQuiz(category);
      errorMessage = "";
      // 만약 현재 화면에 퀴즈가 없다면(첫 로딩) 바로 _currentQuiz에 세팅
      if (_currentQuiz == null) {
        _currentQuiz = fetched;
      } else {
        // 이미 _currentQuiz가 있다면, 새 퀴즈는 _cachedQuiz에 저장만 해두고
        // 화면 전환은 나중에 commitCachedQuiz()로 수행
        _cachedQuiz = fetched;
      }
    } catch (e) {
      errorMessage = "퀴즈 로드 실패: $e";
    }
    isLoading = false;
    notifyListeners();
  }

  // _cachedQuiz를 실제 화면 표시용(_currentQuiz)으로 적용
  void commitCachedQuiz() {
    if (_cachedQuiz != null) {
      _currentQuiz = _cachedQuiz;
      _cachedQuiz = null;
      notifyListeners();
    }
  }

  // 필요하다면 초기화 로직도 추가 가능
  void reset() {
    _currentQuiz = null;
    _cachedQuiz = null;
    errorMessage = "";
    isLoading = false;
    notifyListeners();
  }
}

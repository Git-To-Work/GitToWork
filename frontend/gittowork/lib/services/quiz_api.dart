import 'api_service.dart';

/// 퀴즈 데이터 모델
class QuizQuestion {
  final String category;          // "CL", "CS", "FI", "SS"
  final String type;              // "ox" or "2choice"
  final int questionId;           // 문제 번호
  final String questionText;      // 문제 텍스트
  final List<String> choices;     // 선택지 ["O","X"] 또는 ["선택지A","선택지B"]
  final int correctAnswerIndex;   // 정답 인덱스
  final String feedback;          // 피드백

  QuizQuestion({
    required this.category,
    required this.type,
    required this.questionId,
    required this.questionText,
    required this.choices,
    required this.correctAnswerIndex,
    required this.feedback,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      category: json['category'] as String,
      type: json['type'] as String,
      questionId: json['questionId'] as int,
      questionText: json['questionText'] as String,
      choices: (json['choices'] as List).map((e) => e as String).toList(),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      feedback: json['feedback'] as String,
    );
  }
}

class QuizApi {
  static Future<QuizQuestion> fetchQuiz(String category) async {
    try {
      final response = await ApiService.dio.get(
        '/api/quiz/select',
        queryParameters: {'category': category},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 200) {
          return QuizQuestion.fromJson(data['results']);
        } else {
          throw Exception('퀴즈 데이터를 불러오는 중 오류 발생. code: ${data['code']}');
        }
      } else {
        throw Exception('퀴즈 데이터를 불러오는 중 오류 발생. status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}


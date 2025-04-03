import 'package:flutter/material.dart';

class GitHubAnalysisProvider extends ChangeNotifier {
  String _repoName = '';
  String _lastAnalysis = '';
  String _overallScore = '';
  Map<String, dynamic> _activityMetrics = {};
  Map<String, dynamic> _aiAnalysis = {};
  Map<String, dynamic> _languageRatios = {};

  String get repoName => _repoName;
  String get lastAnalysis => _lastAnalysis;
  String get overallScore => _overallScore;
  Map<String, dynamic> get activityMetrics => _activityMetrics;
  Map<String, dynamic> get aiAnalysis => _aiAnalysis;
  Map<String, dynamic> get languageRatios => _languageRatios;
  // { "Python": 60, "JavaScript": 30, "HTML": 10 };

  // ✅ 퍼센트 계산
  double getGradePercent() {
    switch (_overallScore) {
      case 'D': return 0.30;
      case 'C': return 0.4167;
      case 'C+': return 0.5333;
      case 'B': return 0.65;
      case 'B+': return 0.7667;
      case 'A': return 0.8833;
      case 'A+': return 1.0;
      default: return 0.0; // 등급이 없는 경우 0%
    }
  }


  // ✅ 분석 결과 저장
  void updateFromAnalysisResult(Map<String, dynamic> result) {
    _repoName = (result['selectedRepositories'] as List?)?.join(', ') ?? '';
    _lastAnalysis = result['analysisDate'] ?? '';
    _overallScore = result['overallScore'] ?? '';
    _activityMetrics = result['activityMetrics'] ?? {};
    _aiAnalysis = result['aiAnalysis'] ?? {};
    _languageRatios = result['languageRatios'] ?? {};
    notifyListeners();
  }

  // ✅ 분석 중 상태 처리 (선택 사항)
  void setAnalyzingState() {
    _repoName = '';
    _lastAnalysis = '';
    _overallScore = '';
    _activityMetrics = {};
    _aiAnalysis = {};
    _languageRatios = {};
    notifyListeners();
  }
}

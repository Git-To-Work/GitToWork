import 'package:flutter/material.dart';

class GitHubAnalysisProvider extends ChangeNotifier {
  String _repoName = '';
  String _lastAnalysis = '';
  String _overallScore = '';
  Map<String, dynamic> _activityMetrics = {};
  Map<String, dynamic> _aiAnalysis = {};
  Map<String, dynamic> _languageRatios = {};
  bool _isAnalyzing = false;

  // 🔓 Getters
  String get repoName => _repoName;
  String get lastAnalysis => _lastAnalysis;
  String get overallScore => _overallScore;
  Map<String, dynamic> get activityMetrics => _activityMetrics;
  Map<String, dynamic> get aiAnalysis => _aiAnalysis;
  Map<String, dynamic> get languageRatios => _languageRatios;
  bool get isAnalyzing => _isAnalyzing;

  // ✅ 분석 등급 → 퍼센트
  double getGradePercent() {
    switch (_overallScore) {
      case 'D': return 0.30;
      case 'C': return 0.4167;
      case 'C+': return 0.5333;
      case 'B': return 0.65;
      case 'B+': return 0.7667;
      case 'A': return 0.8833;
      case 'A+': return 1.0;
      default: return 0.0;
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
    _isAnalyzing = false; // ✅ 분석 완료 → false
    notifyListeners();
  }

  // ✅ 분석 중 상태 설정
  void setAnalyzing(bool value) {
    _isAnalyzing = value;
    if (value) {
      // 분석 중일 때 기존 결과 초기화 (선택)
      _repoName = '';
      _lastAnalysis = '';
      _overallScore = '';
      _activityMetrics = {};
      _aiAnalysis = {};
      _languageRatios = {};
    }
    notifyListeners();
  }

  // ✅ 기존 코드 호환용 (삭제해도 무방)
  void setAnalyzingState() {
    setAnalyzing(true);
  }
}

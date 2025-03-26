import 'package:flutter/material.dart';

class GitHubAnalysisProvider extends ChangeNotifier {
  String _repoName = 'mkos47635';
  String _lastAnalysis = '2025/03/11 13:03:13';

  String get repoName => _repoName;
  String get lastAnalysis => _lastAnalysis;

  List<int> _testData = [1, 2, 3];
  List<int> get testData => _testData;

  void updateRepoInfo(String newRepoName, String newTime) {
    _repoName = newRepoName;
    _lastAnalysis = newTime;
    notifyListeners();
  }

}

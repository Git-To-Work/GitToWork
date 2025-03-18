import 'package:flutter/material.dart';

class GitHubAnalysisProvider extends ChangeNotifier {
  List<int> _testData = [1, 2, 3];

  List<int> get testData => _testData;

  /// 모든 숫자에 1을 더해서 업데이트합니다.
  void incrementTestData() {
    _testData = _testData.map((value) => value + 1).toList();
    notifyListeners();
  }
}

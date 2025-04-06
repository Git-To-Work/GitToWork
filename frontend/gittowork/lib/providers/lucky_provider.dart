import 'package:flutter/material.dart';

class LuckyProvider with ChangeNotifier {
  // 사용자 정보
  String _birthDate = '';
  String _gender = '';
  String _birthTime = '';

  // 운세 결과
  String _overall = '정통운세 · 월간종합운세. 이달의 총론과 재물, 애정, 건강, 기일 등 7가지 테마를 설정하여 안내해드려요. · 평생운세. 나의 운명을 미리 알고 활용해보세요';
  String _wealth = '';
  String _love = '';
  String _study = '';
  String _fortuneDate = '오늘'; // 운세 날짜

  // Getters
  String get birthDate => _birthDate;
  String get gender => _gender;
  String get birthTime => _birthTime;

  String get overall => _overall;
  String get wealth => _wealth;
  String get love => _love;
  String get study => _study;
  String get fortuneDate => _fortuneDate;

  // Setters - 사용자 정보
  void setBirthDate(String value) {
    _birthDate = value;
    notifyListeners();
  }

  void setBirthTime(String value) {
    _birthTime = value;
    notifyListeners();
  }

  void setGender(String value) {
    _gender = value;
    notifyListeners();
  }

  void setAll({
    required String birthDate,
    required String gender,
    required String birthTime,
  }) {
    _birthDate = birthDate;
    _gender = gender;
    _birthTime = birthTime;
    notifyListeners();
  }

  void clearFortune() {
    _overall = '';
    _wealth = '';
    _love = '';
    _study = '';
    notifyListeners();
  }

  // Setters - 운세 결과
  void setFortune({
    required String overall,
    required String wealth,
    required String love,
    required String study,
  }) {
    _overall = overall;
    _wealth = wealth;
    _love = love;
    _study = study;
    notifyListeners();
  }
}

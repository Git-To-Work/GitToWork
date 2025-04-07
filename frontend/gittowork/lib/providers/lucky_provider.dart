import 'package:flutter/material.dart';

/// 🔸 운세 카테고리 타입 정의
enum FortuneType { all, study, love, wealth }


class LuckyProvider with ChangeNotifier {
  // 사용자 정보
  String _birthDate = '';
  String _gender = '';
  String _birthTime = '';

  // 운세 결과
  FortuneType _selected = FortuneType.all;
  String _overall = '';
  String _wealth = '';
  String _love = '';
  String _study = '';
  String _fortuneDate = '오늘';

  // 상태
  bool _loading = false;

  // Getters
  String get birthDate => _birthDate;
  String get gender => _gender;
  String get birthTime => _birthTime;

  String get overall => _overall;
  String get wealth => _wealth;
  String get love => _love;
  String get study => _study;
  String get fortuneDate => _fortuneDate;
  bool get loading => _loading;
  FortuneType get selected => _selected;

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

  // Setters - 상태
  void setSelected(int value) {
    if(value==0){
      _selected = FortuneType.all;
    }else if(value==1){
      _selected = FortuneType.study;
    }
    else if(value==2){
      _selected = FortuneType.love;
    }
    else{
      _selected = FortuneType.wealth;
    }
    notifyListeners();
  }

  void setLoading() {
    _loading = true;
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
    _study = study;
    _love = love;
    _wealth = wealth;
    _loading = false;
    notifyListeners();
  }
}

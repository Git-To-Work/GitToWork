import 'package:flutter/material.dart';

class SearchFilterProvider extends ChangeNotifier {
  // ✅ My Repo 관련 필드
  String _selectedRepoName = '';
  String _selectedRepoId = '';

  String get selectedRepoName => _selectedRepoName;
  String get selectedRepoId => _selectedRepoId;

  // ✅ 검색어 필터 추가
  String _keyword = '';
  String get keyword => _keyword;

  void updateKeyword(String keyword) {
    _keyword = keyword;
    notifyListeners();
  }

  // ✅ 기타 필터 상태
  String selectedCareer;
  Set<String> selectedTechs;
  Set<String> selectedTags;
  Set<String> selectedRegions;
  bool isHiring;

  SearchFilterProvider({
    this.selectedCareer = '전체',
    Set<String>? selectedTechs,
    Set<String>? selectedTags,
    Set<String>? selectedRegions,
    this.isHiring = false,
  })  : selectedTechs = selectedTechs ?? {},
        selectedTags = selectedTags ?? {},
        selectedRegions = selectedRegions ?? {};

  // ✅ My Repo 업데이트
  void updateSelectedRepo(String name, String id) {
    _selectedRepoName = name;
    _selectedRepoId = id;
    notifyListeners();
  }

  // ✅ 나머지 필터 업데이트
  void updateCareer(String career) {
    selectedCareer = career;
    notifyListeners();
  }

  void updateTechs(Set<String> techs) {
    selectedTechs = techs;
    notifyListeners();
  }

  void updateTags(Set<String> tags) {
    selectedTags = tags;
    notifyListeners();
  }

  void updateRegions(Set<String> regions) {
    selectedRegions = regions;
    notifyListeners();
  }

  void updateIsHiring(bool value) {
    isHiring = value;
    notifyListeners();
  }
}

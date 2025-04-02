import 'package:flutter/material.dart';

class SearchFilterProvider extends ChangeNotifier {
  String selectedCareer;
  Set<String> selectedTechs;
  Set<String> selectedTags;
  Set<String> selectedRegions;

  SearchFilterProvider({
    this.selectedCareer = '전체',
    Set<String>? selectedTechs,
    Set<String>? selectedTags,
    Set<String>? selectedRegions,
  })  : selectedTechs = selectedTechs ?? {},
        selectedTags = selectedTags ?? {},
        selectedRegions = selectedRegions ?? {};

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
}

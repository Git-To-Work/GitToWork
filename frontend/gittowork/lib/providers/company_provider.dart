import 'package:flutter/material.dart';
import 'package:gittowork/services/company_api.dart';

class CompanyProvider extends ChangeNotifier {
  List<Map<String, dynamic>> companies = [];

  Future<void> loadCompaniesFromApi({
    String? selectedRepositoriesId,
    List<String>? techStacks,
    List<String>? field,
    String? career,
    String? location,
    String? keword,
    String? page,
    String? size,
  }) async {
    try {
      final result = await CompanyApi.fetchRecommendedCompanies(
        selectedRepositoriesId: selectedRepositoriesId,
        techStacks: techStacks,
        field: field,
        career: career,
        location: location,
        keword: keword,
        page: page,
        size: size,
      );
      // result['companies']가 List<dynamic>라고 가정합니다.
      companies = (result['companies'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      debugPrint("CompanyData: companies loaded: $companies");
      notifyListeners();
    } catch (error) {
      debugPrint("CompanyData loadCompaniesFromApi error: $error");
      rethrow;
    }
  }
}

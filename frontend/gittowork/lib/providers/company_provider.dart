import 'package:flutter/material.dart';
import 'package:gittowork/services/company_api.dart';

class CompanyProvider extends ChangeNotifier {
  List<Map<String, dynamic>> companies = [];

  Future<void> loadCompaniesFromApi({
    required BuildContext context,
    required String page,
    required String size,
    bool reset = false,
  }) async {
    try {
      final result = await CompanyApi.fetchRecommendedCompanies(
        context: context,
      );

      final newCompanies = (result['companies'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      if (reset) {
        companies = newCompanies;
      } else {
        companies.addAll(newCompanies);
      }

      notifyListeners();
    } catch (error) {
      debugPrint("loadCompaniesFromApi error: $error");
      rethrow;
    }
  }


  /// 스크랩 처리 저장
  void updateScrapStatus(int companyId, bool isScraped) {
    for (var company in companies) {
      if (company['company_id'] == companyId) {
        company['scraped'] = isScraped;
        break;
      }
    }
    notifyListeners();
  }
}

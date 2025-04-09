import 'package:flutter/material.dart';
import 'package:gittowork/providers/search_provider.dart';
import 'package:gittowork/services/company_api.dart';
import 'package:provider/provider.dart';

class CompanyProvider extends ChangeNotifier {
  List<Map<String, dynamic>> companies = [];

  Future<void> loadCompaniesFromApi({
    required BuildContext context,
    required String page,
    required String size,
    bool reset = false,
  }) async {
    try {
      final filterProvider = Provider.of<SearchFilterProvider>(context, listen: false);
      final result = await CompanyApi.fetchRecommendedCompanies(
        context: context,
        keyword: filterProvider.keyword,
        page: int.parse(page),
        size: int.parse(size),
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

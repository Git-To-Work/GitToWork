import 'package:flutter/material.dart';
import 'package:gittowork/services/company_api.dart';

class CompanyDetailProvider extends ChangeNotifier {
  Map<String, dynamic>? companyDetail;

  Future<void> loadCompanyDetailFromApi({required int companyId}) async {
    try {
      final result = await CompanyApi.fetchCompanyDetail(companyId);
      companyDetail = result;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }
}

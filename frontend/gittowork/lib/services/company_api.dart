import 'package:flutter/cupertino.dart';
import 'api_service.dart';

class CompanyApi {

  /// 추천 기업 리스트 조회
  static Future<Map<String, dynamic>> fetchRecommendedCompanies({
    String? selectedRepositoriesId,
    List<String>? techStacks,
    List<String>? field,
    String? career,
    String? location,
    String? keword,
    String? page,
    String? size,
  }) async {
    final queryParameters = {
      // 'selected_repositories_id': selectedRepositoriesId ?? "",
      'techStacks': techStacks ?? [],
      'field': field ?? [],
      // 'career': career ?? 0,
      'location': location ?? "",
      'keword': keword ?? "",
      'page': page ?? 1.toString(),
      'size': size ?? 20.toString(),
    };

    final response = await FastApiService.dio.get(
      '/select/companies',
      queryParameters: queryParameters,
    );

    debugPrint("Response data: ${response.data}");

    if (response.statusCode == 200) {
      final results = response.data['result'];
      if (results == null) {
        throw Exception('응답 데이터에 값이 없습니다.');
      }
      return results as Map<String, dynamic>;
    } else {
      throw Exception('추천 기업 조회 실패: ${response.statusCode}');
    }
  }

  /// 기업 상세 보기
  static Future<Map<String, dynamic>> fetchCompanyDetail(int companyId) async {
    final response = await FastApiService.dio.get('/select/company/$companyId');
    if (response.statusCode == 200) {
      // 응답 데이터 구조에 따라 "result" 키를 사용합니다.
      final result = response.data['result'];
      debugPrint("=============================선택된 기업 데이터 조회=====================================");
      debugPrint("응답 데이터 : ${response.data}");
      debugPrint("=============================선택된 기업 데이터 조회=====================================");
      if (result is Map<String, dynamic>) {
        return result;
      } else {
        throw Exception('Unexpected result format: $result');
      }
    } else {
      throw Exception('회사 상세 조회 실패: ${response.statusCode}');
    }
  }

}

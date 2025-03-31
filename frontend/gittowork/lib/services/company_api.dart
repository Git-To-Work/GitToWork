import 'package:flutter/cupertino.dart';
import 'api_service.dart';

class CompanyApi {
  static String _constructFullUrl(String path, Map<String, dynamic> queryParameters) {
    final baseUrl = FastApiService.dio.options.baseUrl;
    final uri = Uri.parse(baseUrl).replace(path: path, queryParameters: queryParameters);
    return uri.toString();
  }

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

    // 전체 URL 확인
    final fullUrl = _constructFullUrl('/select/companies', queryParameters);
    debugPrint("FAST_API 전체 URL: $fullUrl");

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
}

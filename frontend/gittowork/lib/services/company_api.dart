import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'package:gittowork/providers/search_provider.dart';

class CompanyApi {
  /// 추천 기업 리스트 조회
  static Future<Map<String, dynamic>> fetchRecommendedCompanies({
    required BuildContext context, // context 추가
    String? selectedRepositoriesId,
    List<String>? techStacks,
    List<String>? field,
    String? career,
    String? location,
    String? keword,
    String? page,
    String? size,
  }) async {
    // 🔎 Provider 값 디버깅 출력
    final filterProvider = Provider.of<SearchFilterProvider>(context, listen: false);
    debugPrint("================= 🔍 Provider 필터 상태 =================");
    debugPrint("Selected TechStacks: ${filterProvider.selectedTechs}");
    debugPrint("Selected Tags: ${filterProvider.selectedTags}");
    debugPrint("Selected Career: ${filterProvider.selectedCareer}");
    debugPrint("Selected Regions: ${filterProvider.selectedRegions}");
    debugPrint("=====================================================");

    final queryParameters = {
      'techStacks': techStacks ?? [],
      'field': field ?? [],
      'location': location ?? "",
      'keword': keword ?? "",
      'page': page ?? 1.toString(),
      'size': size ?? 20.toString(),
    };

    final response = await FastApiService.dio.get(
      '/select/companies',
      queryParameters: queryParameters,
    );

    final results = response.data['result'];
    debugPrint("=============================추천 기업 리스트 조회=====================================");
    debugPrint("응답 데이터 : ${response.data}");
    debugPrint("===================================================================================");

    if (response.statusCode == 200) {
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
      final result = response.data['result'];
      debugPrint("=============================선택된 기업 데이터 조회=====================================");
      debugPrint("응답 데이터 : ${response.data}");
      debugPrint("=========================================================================================");
      if (result is Map<String, dynamic>) {
        return result;
      } else {
        throw Exception('Unexpected result format: $result');
      }
    } else {
      throw Exception('회사 상세 조회 실패: ${response.statusCode}');
    }
  }

  /// 기업 좋아요 요청
  static Future<String> likeCompany(int companyId) async {
    final response = await ApiService.dio.post(
      '/api/company-interaction/create/like',
      data: {
        'companyId': companyId,
      },
    );
    if (response.statusCode == 200) {
      final result = response.data['results'];
      return result['message'] ?? '좋아요 요청 완료';
    } else {
      throw Exception('좋아요 요청 실패: ${response.statusCode}');
    }
  }

  /// 기업 좋아요 삭제 요청
  static Future<String> unlikeCompany(int companyId) async {
    final response = await ApiService.dio.delete(
      '/api/company-interaction/delete/like',
      data: {
        'companyId': companyId,
      },
    );
    if (response.statusCode == 200) {
      final result = response.data['results'];
      return result['message'] ?? '좋아요 삭제 완료';
    } else {
      throw Exception('좋아요 삭제 실패: ${response.statusCode}');
    }
  }

  /// 기업 차단 요청
  static Future<String> addCompanyToBlacklist(int companyId) async {
    final response = await ApiService.dio.post(
      '/api/company-interaction/create/blacklist',
      data: {
        'companyId': companyId,
      },
    );

    if (response.statusCode == 200) {
      final result = response.data['results'];
      return result['message'] ?? '차단 기업 추가 완료';
    } else {
      throw Exception('차단 기업 추가 실패: ${response.statusCode}');
    }
  }

  /// 기업 차단 삭제 요청
  static Future<String> removeCompanyFromBlacklist(int companyId) async {
    final response = await ApiService.dio.delete(
      '/api/company-interaction/delete/blacklist',
      data: {
        'companyId': companyId,
      },
    );

    if (response.statusCode == 200) {
      final result = response.data['results'];
      return result['message'] ?? '차단 기업 삭제 완료';
    } else {
      throw Exception('차단 기업 삭제 실패: ${response.statusCode}');
    }
  }

  /// 기업 스크랩 추가 요청
  static Future<String> scrapCompany(int companyId) async {
    final response = await ApiService.dio.post(
      '/api/company-interaction/create/scrap',
      data: {
        'companyId': companyId,
      },
    );

    if (response.statusCode == 200) {
      final result = response.data['results'];
      debugPrint('✅ 스크랩 요청 성공');
      return result['message'] ?? '스크랩 추가 완료';
    } else {
      throw Exception('스크랩 추가 실패: ${response.statusCode}');
    }
  }

  /// 기업 스크랩 삭제 요청
  static Future<String> unscrapCompany(int companyId) async {
    final response = await ApiService.dio.delete(
      '/api/company-interaction/delete/scrap',
      data: {
        'companyId': companyId,
      },
    );

    if (response.statusCode == 200) {
      final result = response.data['results'];
      debugPrint('✅ 스크랩 삭제 성공');
      return result['message'] ?? '스크랩 삭제 완료';
    } else {
      throw Exception('스크랩 삭제 실패: ${response.statusCode}');
    }
  }
}

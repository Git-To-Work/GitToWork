import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'package:gittowork/providers/search_provider.dart';

class CompanyApi {
  /// 추천 기업 리스트 조회
  static Future<Map<String, dynamic>> fetchRecommendedCompanies({
    required BuildContext context,
    String? keyword,
    int page = 1,
    int size = 20,
  }) async {
    final filterProvider = Provider.of<SearchFilterProvider>(context, listen: false);
    final secureStorage = const FlutterSecureStorage();

    String? selectedRepoId = filterProvider.selectedRepoId;
    if (selectedRepoId.isEmpty) {
      selectedRepoId = await secureStorage.read(key: 'selected_repo_id');
    }

    final Map<String, dynamic> queryParameters = {
      if (selectedRepoId != null && selectedRepoId.isNotEmpty)
        'selected_repositories_id': selectedRepoId,
      if (filterProvider.selectedTechs.isNotEmpty)
        'techStacks': filterProvider.selectedTechs.toList(),
      if (filterProvider.selectedTags.isNotEmpty)
        'field': filterProvider.selectedTags.toList(),
      if (filterProvider.selectedCareer.isNotEmpty)
        'career': _mapCareerStringToInt(filterProvider.selectedCareer),
      if (filterProvider.selectedRegions.isNotEmpty)
        'location': filterProvider.selectedRegions.toList(),
      if (keyword != null && keyword.isNotEmpty)
        'keyword': keyword,
      'has_job_notice': filterProvider.isHiring,
      'page': page,
      'size': size,
    };

    debugPrint("🔍 최종 API 호출 파라미터: $queryParameters");

    try {
      final response = await FastApiService.dio.get(
        '/select/companies',
        queryParameters: queryParameters,
      );

      final results = response.data['result'];
      if (response.statusCode == 200) {
        if (results == null) {
          debugPrint("⚠️ 응답 데이터가 null입니다.");
          return {
            'companies': [],
            'analyzing': false,
          };
        }
        debugPrint("[ 회사 데이터 ]: $results");
        return results as Map<String, dynamic>;
      } else {
        debugPrint("❌ 실패 상태 코드: ${response.statusCode}");
        return {
          'companies': [],
          'analyzing': true,
        };
      }
    } catch (e) {
      debugPrint("🚨 API Error: $e");
      return {
        'companies': [],
        'analyzing': true,
      };
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

  /// 기업 분석 요청
  static Future<String> requestCompanyAnalysis() async {
    final secureStorage = const FlutterSecureStorage();
    final selectedRepoId = await secureStorage.read(key: 'selected_repo_id');

    final response = await FastApiService.dio.get(
      '/recommendation/analyze',
      queryParameters: {
        'selected_repositories_id': selectedRepoId,
      },
    );

    if (response.statusCode == 200) {
      final result = response.data['message'];
      requestAction();
      return result ?? 'FastApi 분석 요청 완료';
    } else {
      throw Exception('FastApi 분석 요청 실패: ${response.statusCode}');
    }
  }

  static requestAction() async {
    debugPrint("FastApi recommendation 요청");
    final response = await FastApiService.dio.get(
      '/recommendation',
    );
    debugPrint("✅ requestAction 성공 ${response.data}");
    if (response.statusCode == 200) {
      final result = response.data['message'];
      return result ?? 'FastApi Action  완료';
    } else {
      throw Exception('FastApi Action 요청 실패: ${response.statusCode}');
    }
  }
}

int _mapCareerStringToInt(String career) {
  switch (career) {
    case '전체':
    case '10년 이상':
      return 10;
    case '신입':
      return 0;
    default:
      return int.tryParse(career.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
}

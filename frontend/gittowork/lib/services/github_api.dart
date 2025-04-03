import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../providers/github_analysis_provider.dart';
import 'api_service.dart';
import '../models/repository.dart';
import 'package:flutter/foundation.dart';


class GitHubApi {
  /// 내 레포지토리 조회 API 호출
  static Future<List<Repository>> fetchMyRepositories() async {
    final response = await ApiService.dio.get('/api/github/select/my-repository');
    if (response.statusCode == 200) {
      final data = response.data;
      final results = data['results'];
      final repositories = results['repositories'] as List<dynamic>;
      return repositories.map((json) => Repository.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load repositories: ${response.statusCode}');
    }
  }

  /// 조합된 레포지토리 조회
  static Future<List<RepositoryCombination>> fetchMyRepositoryCombinations() async {
    final response = await ApiService.dio.get('/api/github/select/my-repository-combination');
    if (response.statusCode == 200) {
      final data = response.data;
      final results = data['results'];
      final combinationList = results['repositoryCombinations'] as List<dynamic>;

      return combinationList
          .map((json) => RepositoryCombination.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load repository combinations: ${response.statusCode}');
    }
  }

  /// 선택 레포지토리 저장
  static Future<String> saveSelectedRepository(List<int> repositoryIndices) async {
    debugPrint("리스트 순서 확인해보자잉 ~~~~  : $repositoryIndices");
    final response = await ApiService.dio.post(
      '/api/github/create/save-selected-repository',
      data: {
        'repositories': repositoryIndices,
      },
    );

    debugPrint("saveSelectedRepository response: ${response.data}");
    final data = response.data;
    final code = data['code'];

    if (code == 'DP') {
      debugPrint("❗ 중복된 레포지토리 조합입니다.");
      return '이미 등록된 레포지토리 조합입니다.';
    }

    if (response.statusCode == 200) {
      final results = response.data['results'] ?? {};
      return results['message'] as String;
    } else {
      throw Exception('레포지토리 선택 저장 실패: ${response.statusCode}');
    }
  }


  /// 레포지토리 분석 요청
  static Future<RepositoryAnalysisResponse> requestRepositoryAnalysis(List<int> repositoryIndices) async {
    final response = await ApiService.dio.post(
      '/api/github/create/analysis-by-repository',
      data: {'repositories': repositoryIndices},
    );
    debugPrint("requestRepositoryAnalysis response: ${response.data}");
    if (response.statusCode == 200) {
      return RepositoryAnalysisResponse.fromJson(response.data);
    } else {
      throw Exception('레포지토리 분석 요청 실패: ${response.statusCode}');
    }
  }




  /// 조합 레포지토리 삭제
  static Future<String> deleteRepositoryCombination(String selectedRepositoryId) async {
    final response = await ApiService.dio.delete(
      '/api/github/delete/my-repository-combination',
      queryParameters: {'selectedRepositoryId': selectedRepositoryId},
    );

    debugPrint("Response data: ${response.data}");

    if (response.statusCode == 200) {
      final results = response.data['results'] ?? {};
      debugPrint("Results: $results");
      return results['memberId'] as String? ?? '';
    } else {
      throw Exception('레포지토리 조합 삭제 실패: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> fetchGithubAnalysis({
    required BuildContext context,
    required String selectedRepositoryId,
  }) async {
    debugPrint("[요청 시작] selectedRepositoryId: $selectedRepositoryId");

    try {
      final response = await ApiService.dio.get(
        '/api/github/select/analysis-by-repository',
        queryParameters: {
          'selectedRepositoryId': selectedRepositoryId,
        },
        options: Options(
          validateStatus: (status) => status != null && status <= 404,
        ),
      );

      final provider = Provider.of<GitHubAnalysisProvider>(context, listen: false);

      if (response.statusCode == 200) {
        final results = response.data['results'];
        debugPrint("[분석 결과 데이터] : $results");

        provider.updateFromAnalysisResult(results);
        return {'analyzing': false};
      } else if (response.statusCode == 404) {
        debugPrint("🕒 분석 중 상태입니다. (404)");

        provider.setAnalyzing(true); // ✅ 분석 중 상태 저장
        return {'analyzing': true};
      } else {
        throw Exception('깃허브 분석 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ [분석 데이터 조회 실패] $e");
      rethrow;
    }
  }



}

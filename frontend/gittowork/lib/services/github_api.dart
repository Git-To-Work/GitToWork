import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../providers/github_analysis_provider.dart';
import 'api_service.dart';
import '../models/repository.dart';
import 'company_api.dart';

class GitHubApi {
  /// 내 레포지토리 조회 API 호출
  static Future<List<Repository>> fetchMyRepositories() async {
    final response =
    await ApiService.dio.get('/api/github/select/my-repository');
    if (response.statusCode == 200) {
      final data = response.data;
      final results = data['results'];
      final repositories = results['repositories'] as List<dynamic>;
      return repositories
          .map((json) => Repository.fromJson(json))
          .toList();
    } else {
      throw Exception(
          'Failed to load repositories: ${response.statusCode}');
    }
  }

  /// 조합된 레포지토리 조회
  static Future<List<RepositoryCombination>>
  fetchMyRepositoryCombinations() async {
    final response = await ApiService.dio
        .get('/api/github/select/my-repository-combination');
    if (response.statusCode == 200) {
      final data = response.data;
      final results = data['results'];
      final combinationList =
      results['repositoryCombinations'] as List<dynamic>;
      return combinationList
          .map((json) => RepositoryCombination.fromJson(json))
          .toList();
    } else {
      throw Exception(
          'Failed to load repository combinations: ${response.statusCode}');
    }
  }

  /// 선택 레포지토리 저장
  static Future<String> saveSelectedRepository(List<int> repositoryIndices) async {
    debugPrint("리스트 순서 확인해보자잉 ~~~~  : $repositoryIndices");

    try {
      final response = await ApiService.dio.post(
        '/api/github/create/save-selected-repository',
        data: {
          'repositories': repositoryIndices,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500, // 400도 통과
        ),
      );

      debugPrint("saveSelectedRepository response: ${response.data}");
      final data = response.data;
      final code = data['code'];

      if (code == 'DP') {
        debugPrint("❗ 중복된 레포지토리 조합입니다.");
        return '이미 등록된 레포지토리 조합입니다.';
      }

      if (response.statusCode == 200) {
        final results = data['results'] ?? {};
        return results['message'] as String? ?? '저장되었습니다.';
      } else {
        throw Exception('레포지토리 선택 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ 레포지토리 선택 저장 실패: $e");
      rethrow;
    }
  }


  /// 레포지토리 분석 요청
  static Future<RepositoryAnalysisResponse> requestRepositoryAnalysis(
      BuildContext context,
      List<int> repositoryIndices) async {
    final response = await ApiService.dio.post(
      '/api/github/create/analysis-by-repository',
      data: {'repositories': repositoryIndices},
    );

    final provider = Provider.of<GitHubAnalysisProvider>(context, listen: false);

    if (response.statusCode == 200) {
      final results = response.data['results'];

      final selectedRepositoryId = results['selectedRepositoryId']; // ← 필드명 맞게 확인

      if (selectedRepositoryId != null) {
        const storage = FlutterSecureStorage();
        await storage.write(
          key: 'selected_repo_id',
          value: selectedRepositoryId.toString(),
        );
        debugPrint("🔐 selected_repo_id 저장 완료: $selectedRepositoryId");
      }

      provider.setAnalyzing(results);

      await CompanyApi.requestCompanyAnalysis();

      return RepositoryAnalysisResponse.fromJson(response.data);
    } else {
      throw Exception('레포지토리 분석 요청 실패: ${response.statusCode}');
    }
  }


  /// 조합 레포지토리 삭제
  static Future<String> deleteRepositoryCombination(
      String selectedRepositoryId) async {
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
      throw Exception(
          '레포지토리 조합 삭제 실패: ${response.statusCode}');
    }
  }

  /// 분석 결과 조회
  static Future<Map<String, dynamic>> fetchGithubAnalysis({
    required BuildContext context,
    required String selectedRepositoryId,
  }) async {
    debugPrint("[요청 시작] selectedRepositoryId: $selectedRepositoryId");

    final provider = Provider.of<GitHubAnalysisProvider>(context, listen: false);
    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    await secureStorage.write(
      key: 'selected_repo_id',
      value: selectedRepositoryId,
    );

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

      if (response.statusCode == 200) {
        final results = response.data['results'];
        debugPrint("[분석 결과 데이터] : $results");

        if(results['status']=='complete'){
          debugPrint("✅분석 성공✅");
          provider.updateFromAnalysisResult(results);
        }
        else if(results['status']=='analyzing'){
          debugPrint("🕒분석 진행중🕒");
          provider.updateFromAnalysisResult(results);
          provider.setStatus();
        }
        else if(results['status']=='fail'){
          debugPrint("❌분석  실패❌");
          provider.setFail();
        }
        return results;

      } else {
        throw Exception('깃허브 분석 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      provider.setFail();
      debugPrint("❌ [분석 데이터 조회 실패] $e");
      rethrow;
    }
  }
}

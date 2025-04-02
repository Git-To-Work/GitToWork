import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:gittowork/services/api_service.dart';

class CoverLetterApi {
  /// GET /api/cover-letter/select/list
  static Future<List<dynamic>> fetchCoverLetterList() async {
    try {
      final response = await ApiService.dio.get('/api/cover-letter/select/list');

      if (response.statusCode == 200) {
        final results = response.data['results'];
        if (results != null && results['files'] != null) {
          return results['files'] as List<dynamic>;
        } else {
          return [];
        }
      } else {
        throw Exception('자기소개서 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST /api/cover-letter/create
  /// 단일 PDF 파일과 title 을 multipart/form-data 로 전송
  static Future<void> createCoverLetter({
    required String title,
    required File file,
  }) async {
    try {
      final fileName = file.path.split('/').last;

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
        'title': title,
      });

      final response = await ApiService.dio.post(
        '/api/cover-letter/create',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode != 200) {
        throw Exception('자기소개서 업로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE /api/cover-letter/delete
  /// coverLetterId (int) 파라미터 필요
  static Future<void> deleteCoverLetter(int coverLetterId) async {
    try {
      final response = await ApiService.dio.delete(
        '/api/cover-letter/delete',
        queryParameters: {
          'coverLetterId': coverLetterId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('자기소개서 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// GET api/cover-letter/select/analysis
  static Future<Map<String, dynamic>> getCoverLetterAnalysis(int coverLetterId) async {
    try {
      final response = await ApiService.dio.get(
        '/api/cover-letter/select/analysis',
        queryParameters: {
          'coverLetterId': coverLetterId,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('자기소개서 분석 조회 실패: ${response.statusCode}');
      }
      return response.data;
    } catch (e) {
      rethrow; // 필요한 형태로 에러 처리
    }
  }
}

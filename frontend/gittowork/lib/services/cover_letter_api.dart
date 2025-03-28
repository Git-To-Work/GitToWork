import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gittowork/services/api_service.dart';

// (필요하다면) cover_letter_model.dart에서 아래 처럼 모델 정의 후 import
// class CoverLetterItem {
//   final int fileId;
//   final String fileName;
//   final String fileUrl;
//   final String title;
//
//   CoverLetterItem({
//     required this.fileId,
//     required this.fileName,
//     required this.fileUrl,
//     required this.title,
//   });
//
//   factory CoverLetterItem.fromJson(Map<String, dynamic> json) {
//     return CoverLetterItem(
//       fileId: json['fileId'] as int,
//       fileName: json['fileName'] as String,
//       fileUrl: json['fileUrl'] as String,
//       title: json['title'] as String,
//     );
//   }
// }

class CoverLetterApi {
  /// GET /api/cover-letter/select/list
  static Future<List<dynamic>> fetchCoverLetterList() async {
    try {
      final response = await ApiService.dio.get('/api/cover-letter/select/list');

      if (response.statusCode == 200) {
        // API 예시 응답 형태: { "files": [ { "fileId":..., "fileName":..., "fileUrl":..., "title":... }, ... ] }
        final data = response.data['files'] as List<dynamic>;
        // 필요한 경우, 모델로 파싱
        // return data.map((e) => CoverLetterItem.fromJson(e)).toList();
        return data;
      } else {
        throw Exception('자기소개서 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST /api/cover-letter/create
  ///
  /// - file: NotNull, 단일 파일 (pdf 등)
  /// - title: NotNull (multipart/form-data로 같이 전송)
  static Future<void> createCoverLetter({
    required File file,
    required String title,
  }) async {
    try {
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
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
}

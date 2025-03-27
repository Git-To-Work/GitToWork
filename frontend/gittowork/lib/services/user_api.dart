import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';
import '../screens/signup/business_interest_screen.dart';
import 'api_service.dart';

class UserApi {
  static Future<UserProfile> fetchUserProfile(String accessToken) async {
    ApiService.dio.options.headers['authorization'] = 'Bearer $accessToken';
    final response = await ApiService.dio.get('/api/user/select/profile');
    if (response.statusCode == 200) {
      final data = response.data;
      final result = data['results'];
      return UserProfile.fromJson(result);
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  /// 회원가입 정보 전송 메서드
  static Future<bool> sendSignupData(Map<dynamic, dynamic> signupParams) async {
    try {
      final token = await const FlutterSecureStorage().read(key: 'jwt_token');
      debugPrint('JWT 토큰: $token');
      final response = await ApiService.dio.post(
        '/api/user/create/profile',
        data: signupParams,
        options: Options(headers: {
          'authorization': 'Bearer $token',
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('회원가입 성공: ${response.data}');
        return true;
      } else {
        debugPrint('회원가입 실패(서버 에러): ${response.statusCode}');
        return false;
      }
    } catch (error) {
      debugPrint('회원가입 실패(예외 발생): $error');
      return false;
    }
  }

  static Future<List<BusinessField>> fetchInterestFields() async {
    try {
      final token = await const FlutterSecureStorage().read(key: 'jwt_token');
      final response = await ApiService.dio.get(
        '/api/user/select/interest-field-list',
        options: Options(headers: {
          'authorization': 'Bearer $token',
        }),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'];
        final fields = results['fields'] as List<dynamic>?;
        if (fields == null) {
          debugPrint('관심 분야 목록이 null 상태입니다.');
          return [];
        }
        return fields.map((json) {
          return BusinessField(
            fieldId: json['id'] as int,
            fieldName: json['fieldName'] as String,
            logoUrl: json['fieldLogoUrl'] as String?,
          );
        }).toList();
      } else {
        throw Exception('관심 분야 목록 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('관심 분야 목록 에러: $e');
      return [];
    }
  }

  static Future<bool> updateInterestFields(List<int> interestFields) async {
    try {
      final token = await const FlutterSecureStorage().read(key: 'jwt_token');
      debugPrint('JWT 토큰: $token');
      final response = await ApiService.dio.post(
        '/api/user/update/interest-field',
        data: {'interestFields': interestFields},
        options: Options(headers: {
          'authorization': 'Bearer $token',
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('관심 분야 업데이트 성공: ${response.data}');
        return true;
      } else {
        debugPrint('관심 분야 업데이트 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('관심 분야 업데이트 에러: $e');
      return false;
    }
  }
}

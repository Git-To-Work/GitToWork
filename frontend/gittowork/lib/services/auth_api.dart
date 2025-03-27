import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class SignInResponse {
  final String nickname;
  final String accessToken;
  final bool privacyPolicyAgreed;
  final String avatarUrl;

  SignInResponse({
    required this.nickname,
    required this.accessToken,
    required this.privacyPolicyAgreed,
    required this.avatarUrl,
  });

  factory SignInResponse.fromJson(Map<String, dynamic> json) {
    final results = json['results'] ?? {};
    return SignInResponse(
      accessToken: results['accessToken'] as String,
      nickname: results['nickname'] as String,
      privacyPolicyAgreed: results['privacyPolicyAgreed'] as bool,
      avatarUrl: results['avatarUrl'] as String,
    );
  }
}

class AuthApi {
  static Future<SignInResponse> signInWithGitHub(String code) async {
    debugPrint('GITHUB API code: $code');
    final response = await ApiService.dio.post(
      '/api/auth/create/signin',
      data: {'code': code},
    );
    if (response.statusCode == 200) {
      return SignInResponse.fromJson(response.data);
    } else {
      throw Exception('백엔드 인증 실패: ${response.statusCode}');
    }
  }

  static Future<bool> loginWithExistingToken(String token) async {
    try {
      ApiService.dio.options.headers['authorization'] = 'Bearer $token';
      final response = await ApiService.dio.post('/api/auth/create/login');
      return response.statusCode == 200;
    } catch (error) {
      debugPrint('자동 로그인 실패: $error');
      return false;
    }
  }

  static Future<bool> logout() async {
    try {
      final token = await const FlutterSecureStorage().read(key: 'jwt_token');
      if (token == null) {
        debugPrint('토큰이 없습니다. 로그아웃 수행 불가');
        return false;
      }
      ApiService.dio.options.headers['authorization'] = 'Bearer $token';
      final response = await ApiService.dio.post('/api/auth/create/logout');
      if (response.statusCode == 200) {
        debugPrint('로그아웃 성공: ${response.data}');
        await const FlutterSecureStorage().delete(key: 'jwt_token');
        return true;
      } else {
        debugPrint('로그아웃 실패(서버 에러): ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('로그아웃 실패(예외 발생): $e');
      return false;
    }
  }

  static Future<bool> withdrawAccount() async {
    try {
      final token = await const FlutterSecureStorage().read(key: 'jwt_token');
      if (token == null) {
        debugPrint('토큰이 없습니다. 회원탈퇴 수행 불가');
        return false;
      }
      ApiService.dio.options.headers['authorization'] = 'Bearer $token';
      final response = await ApiService.dio.post('/api/user/delete/account');
      if (response.statusCode == 200) {
        debugPrint('회원탈퇴 성공: ${response.data}');
        await const FlutterSecureStorage().delete(key: 'jwt_token');
        return true;
      } else {
        debugPrint('회원탈퇴 실패(서버 에러): ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('회원탈퇴 실패(예외 발생): $e');
      return false;
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_profile.dart';

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
    return SignInResponse(
      nickname: json['nickname'] as String,
      accessToken: json['accessToken'] as String,
      privacyPolicyAgreed: json['privacyPolicyAgreed'] as bool,
      avatarUrl: json['avatarUrl'] as String,
    );
  }
}

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      headers: {
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(milliseconds: 3000),
    ),
  );

  Future<SignInResponse> signInWithGitHub(String code) async {
    debugPrint('GITHUB API code : $code');
    final response = await _dio.post(
      '/api/auth/create/signin',
      data: {'code': code},
    );
    if (response.statusCode == 200) {
      return SignInResponse.fromJson(response.data);
    } else {
      throw Exception('백엔드 인증 실패: ${response.statusCode}');
    }
  }

  Future<bool> loginWithExistingToken(String token) async {
    try {
      _dio.options.headers['authorization'] = 'Bearer $token';

      final response = await _dio.post('/api/auth/create/login');
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      debugPrint('자동 로그인 실패: $error');
      return false;
    }
  }

  Future<UserProfile> fetchUserProfile(String accessToken) async {
    // 토큰이 필요하다면 아래와 같이 설정
    _dio.options.headers['authorization'] = 'Bearer $accessToken';

    final response = await _dio.get('/api/user/select/profile');
    if (response.statusCode == 200) {
      final data = response.data;
      final result = data['result'];
      return UserProfile.fromJson(result);
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  /// 회원가입 정보 전송 메서드
  /// [signupParams]에는 아래 파라미터들이 모두 포함되어 있어야 합니다.
  /// - experience
  /// - interestsFields (최대 5개)
  /// - name
  /// - birthDt (0000-00-00 형식)
  /// - phone (010-0000-0000 형식)
  /// - privacyPolicyAgreed (true/false)
  /// - notificationAgreed (true/false)
  static Future<bool> sendSignupData(Map<dynamic, dynamic> signupParams) async {
    try {
      // 만약 Authorization 헤더가 필요하면 미리 세팅 (토큰 보유 시)
      // _dio.options.headers['authorization'] = 'Bearer YOUR_TOKEN';

      final response = await _dio.post(
        '/api/user/create/profile',
        data: signupParams,
      );

      if (response.statusCode == 200) {
        debugPrint('회원가입 성공: ${response.data}');
        return true;
        // 추가 로직 (예: 저장, 화면 이동 등)
      } else {
        debugPrint('회원가입 실패(서버 에러): ${response.statusCode}');
        return false;
      }
    } catch (error) {
      debugPrint('회원가입 실패(예외 발생): $error');
      return false;
    }
  }
}

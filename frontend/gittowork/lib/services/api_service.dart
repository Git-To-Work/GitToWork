import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';
import '../screens/signup/business_interest_screen.dart';

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
      final result = data['results'];
      return UserProfile.fromJson(result);
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  /// 회원가입 정보 전송 메서드
  static Future<bool> sendSignupData(Map<dynamic, dynamic> signupParams) async {
    try {
      final token = await FlutterSecureStorage().read(key: 'jwt_token');
      debugPrint('JWT 토큰: $token');
      final response = await _dio.post(
        '/api/user/create/profile',
        data: signupParams,
        options: Options(headers: {
          'authorization': 'Bearer $token',
        }),
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

  static Future<List<BusinessField>> fetchInterestFields() async {
    try {
      final token = await FlutterSecureStorage().read(key: 'jwt_token');
      final response = await _dio.get(
        '/api/user/select/interest-field-list',
        options: Options(headers: {
          'authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data['fields'] as List;
        return data.map((json) => BusinessField(
          fieldId: json['fieldId'],
          fieldName: json['fieldName'],
          logoUrl: json['logoUrl'],
        )).toList();
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
      final token = await FlutterSecureStorage().read(key: 'jwt_token');
      debugPrint('JWT 토큰: $token');
      final response = await _dio.post(
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

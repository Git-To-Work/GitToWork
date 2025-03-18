import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<SignInResponse> signInWithGitHub(String code) async {
    // 백엔드에서 요구하는 Bearer 토큰. 예를 들어, 앱에서 관리하는 정적인 토큰이나
    // 별도로 저장된 값을 사용할 수 있습니다.
    final backendAuthToken = 'your_backend_token';

    _dio.options.headers['authorization'] = 'Bearer $backendAuthToken';

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
}
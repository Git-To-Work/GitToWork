import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      headers: {
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(milliseconds: 10000),
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 저장된 토큰이 있으면 authorization 헤더에 추가
        final token = await _storage.read(key: 'jwt_token');
        if (token != null && token.isNotEmpty) {
          options.headers['authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ),
  );
}

class FastApiService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['FAST_API_BASE_URL'] ?? '',
      headers: {
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(milliseconds: 10000),
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 저장된 토큰이 있으면 authorization 헤더에 추가
        final token = await _storage.read(key: 'jwt_token');
        if (token != null && token.isNotEmpty) {
          options.headers['authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ),
  );
}
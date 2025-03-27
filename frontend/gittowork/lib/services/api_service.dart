import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      headers: {
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(milliseconds: 3000),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:gittowork/services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/lucky_provider.dart'; // LuckyProvider 경로 맞춰서 수정

class LuckyService {
  /// 사용자 정보 서버에 저장
  static Future<void> saveFortuneUserInfo(BuildContext context) async {
    final luckyProvider = Provider.of<LuckyProvider>(context, listen: false);

    final birthDt = luckyProvider.birthDate;
    final sex = luckyProvider.gender;
    final birthTm = luckyProvider.birthTime;

    try {
      final response = await ApiService.dio.post(
        '/api/fortune/create/info',
        data: {
          'birthDt': birthDt,
          'sex': sex,
          'birthTm': birthTm,
        },
      );
      debugPrint("✅ 사용자 정보 저장: ${response.data}");
      if (response.statusCode == 200) {
        debugPrint("✅ 사용자 정보 저장 성공: ${response.data['results']['message']}");
      } else {
        throw Exception('❌ 사용자 정보 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 사용자 정보 저장 중 예외 발생: $e');
    }
  }

  /// 사용자 정보 조회 후 Provider에 저장
  static Future<void> getFortuneUserInfoWithProvider(BuildContext context) async {
    try {
      final response = await ApiService.dio.get('/api/fortune/select/info');

      if (response.statusCode == 200) {
        final results = response.data['results'];
        final birthDt = results['birthDt'] ?? '';
        final sex = results['sex'] ?? '';
        final birthTm = results['birthTm'] ?? '';

        // ✅ birthTm: "11:00" → "11:00 ~ 11:30"
        final birthTmRange = _toTimeRange(birthTm);

        // Provider에 저장
        Provider.of<LuckyProvider>(context, listen: false).setAll(
          birthDate: birthDt,
          gender: sex,
          birthTime: birthTmRange, // ✅ 범위 문자열 저장
        );
      } else {
        debugPrint('❌ 사용자 정보 없음: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 사용자 정보 조회 중 예외 발생: $e');
    }
  }


  /// 오늘의 운세 조회
  static Future<void> getTodayFortune(
      BuildContext context) async {
    final luckyProvider = Provider.of<LuckyProvider>(context, listen: false);

    final birthDt = luckyProvider.birthDate;
    final sex = luckyProvider.gender;
    final birthTm = luckyProvider.birthTime;

    final response = await ApiService.dio.post(
      '/api/fortune/create/today',
      data: {
        'birthDt': birthDt,
        'sex': sex,
        'birthTm': birthTm,
      },
    );

    if (response.statusCode == 200) {
      final fortune = response.data['results']['fortune'];
      debugPrint("💬 API 응답: $fortune");

      final provider = Provider.of<LuckyProvider>(context, listen: false);

      provider.setFortune(
        overall: fortune['overall'],
        wealth: fortune['wealth'],
        love: fortune['love'],
        study: fortune['study'],
      );

      debugPrint("✅ 저장 확인 - overall: ${provider.overall}");
      debugPrint("✅ 저장 확인 - wealth: ${provider.wealth}");
      debugPrint("✅ 저장 확인 - love: ${provider.love}");
      debugPrint("✅ 저장 확인 - study: ${provider.study}");
    }

    else{
      Provider.of<LuckyProvider>(context, listen: false).clearFortune();
    }
  }

  static String _toTimeRange(String startTime) {
    if (!startTime.contains(':')) return startTime;

    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    int endHour = hour;
    int endMinute = minute + 30;
    if (endMinute >= 60) {
      endMinute -= 60;
      endHour = (hour + 1) % 24;
    }

    final end = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
    return '$startTime ~ $end';
  }

}

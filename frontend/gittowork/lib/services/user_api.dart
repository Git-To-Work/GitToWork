import 'package:flutter/cupertino.dart';
import '../models/company.dart';
import '../models/interest_field.dart';
import '../models/user_profile.dart';
import '../screens/signup/business_interest_screen.dart';
import 'api_service.dart';

class UserApi {
  /// 회원가입 정보 전송 메서드
  static Future<bool> sendSignupData(Map<dynamic, dynamic> signupParams) async {
    try {
      // ApiService 인터셉터가 토큰을 자동으로 추가합니다.
      final response = await ApiService.dio.post(
        '/api/user/create/profile',
        data: signupParams,
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
      final response = await ApiService.dio.get(
        '/api/user/select/interest-field-list',
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

  /// 사용자 프로필 조회 (관심 분야 제외)
  static Future<UserProfile> fetchUserProfile() async {
    final response = await ApiService.dio.get('/api/user/select/profile');
    if (response.statusCode == 200) {
      return UserProfile.fromJson(response.data);
    } else {
      throw Exception('사용자 프로필 조회 실패: ${response.statusCode}');
    }
  }

  /// 관심 분야(ID, 이름) 조회
  static Future<InterestField> fetchUserInterestField() async {
    final response = await ApiService.dio.get('/api/user/select/my-interest-field');
    if (response.statusCode == 200) {
      return InterestField.fromJson(response.data);
    } else {
      throw Exception('관심 분야 조회 실패: ${response.statusCode}');
    }
  }

  /// 사용자 프로필 수정
  /// (예: name, birthDt, experience, phone, notificationAgreed)
  static Future<bool> updateUserProfile(Map<String, dynamic> updateParams) async {
    try {
      final response = await ApiService.dio.put(
        '/api/user/update/profile',
        data: updateParams,
      );
      if (response.statusCode == 200) {
        debugPrint('회원 정보 수정 성공: ${response.data}');
        return true;
      } else {
        debugPrint('회원 정보 수정 실패(서버 에러): ${response.statusCode}');
        return false;
      }
    } catch (error) {
      debugPrint('회원 정보 수정 실패(예외 발생): $error');
      return false;
    }
  }

  /// 관심 분야 수정 (ID 목록만 전송)
  static Future<bool> updateInterestFields(List<int> interestFieldIds) async {
    try {
      final response = await ApiService.dio.put(
        '/api/user/update/interest-field',
        data: {'interestsFields': interestFieldIds},
      );
      debugPrint('관심 분야 업데이트 요청: $interestFieldIds');
      if (response.statusCode == 200) {
        debugPrint('관심 분야 업데이트 성공');
        return true;
      } else {
        debugPrint('관심 분야 업데이트 실패(서버 에러): ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('관심 분야 업데이트 예외 발생: $e');
      return false;
    }
  }

  // FCM 토큰
  static Future<bool> updateFcmToken(String token) async {
    try {
      final response = await ApiService.dio.post(
        '/api/firebase/create/fcm-token',
        data: {'fcmToken': token},
      );
      if (response.statusCode == 200) {
        debugPrint('FCM 토큰 등록/수정 성공: ${response.data}');
        return true;
      } else {
        debugPrint('FCM 토큰 등록/수정 실패(서버 에러): ${response.statusCode}');
        return false;
      }
    } catch (error) {
      debugPrint('FCM 토큰 등록/수정 실패(예외 발생): $error');
      return false;
    }
  }


  // 스크랩 기업 조회
  static Future<List<Company>> fetchScrapCompanies() async {
    final response = await ApiService.dio.get(
      '/api/company-interaction/select/scrap',
      data: {"page": 0, "size": 20},
    );
    if (response.statusCode == 200) {
      final results = response.data['results'];
      final companiesJson = results['companies'] as List<dynamic>;
      debugPrint(companiesJson.toString());
      return companiesJson.map((json) => Company.fromJson(json)).toList();
    } else {
      throw Exception('스크랩 기업 불러오기 실패: ${response.statusCode}');
    }
  }

  // 좋아요 기업 조회
  static Future<List<Company>> fetchLikedCompanies() async {
    final response = await ApiService.dio.get(
      '/api/company-interaction/select/like',
      data: {"page": 0, "size": 20},
    );
    if (response.statusCode == 200) {
      final results = response.data['results'];
      final companiesJson = results['companies'] as List<dynamic>;
      return companiesJson.map((json) => Company.fromJson(json)).toList();
    } else {
      throw Exception('좋아요 기업 불러오기 실패: ${response.statusCode}');
    }
  }

  // 차단한 기업 조회
  static Future<List<Company>> fetchBlockedCompanies() async {
    final response = await ApiService.dio.get(
      '/api/company-interaction/select/blacklist',
      data: {"page": 0, "size": 20},
    );
    if (response.statusCode == 200) {
      final results = response.data['results'];
      final companiesJson = results['companies'] as List<dynamic>;
      return companiesJson.map((json) => Company.fromJson(json)).toList();
    } else {
      throw Exception('차단한 기업 불러오기 실패: ${response.statusCode}');
    }
  }
}

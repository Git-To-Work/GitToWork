class UserProfile {
  final int userId;
  final String? email;
  final String name;
  final String nickname;
  final String phone;
  final String birthDt;
  final int experience;
  final String avatarUrl;
  final List<String> interestFields; // 조회 시 String 배열만 사용
  final bool notificationAgreed;

  UserProfile({
    required this.userId,
    this.email,
    required this.name,
    required this.nickname,
    required this.phone,
    required this.birthDt,
    required this.experience,
    required this.avatarUrl,
    required this.interestFields,
    required this.notificationAgreed,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      email: json['email'],
      name: json['name'],
      nickname: json['nickname'],
      phone: json['phone'],
      birthDt: json['birthDt'],
      experience: json['experience'],
      avatarUrl: json['avatarUrl'],
      interestFields: (json['interestFields'] as List<dynamic>).map((e) => e.toString()).toList(),
      notificationAgreed: json['notificationAgreed'],
    );
  }
}

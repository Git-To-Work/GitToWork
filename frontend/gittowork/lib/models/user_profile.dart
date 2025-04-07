class UserProfile {
  final int userId;
  final String? email;
  final String name;
  final String nickname;
  final String phone;
  final String birthDt;
  final int experience;
  final String avatarUrl;
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
    required this.notificationAgreed,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>;
    return UserProfile(
      userId: results['userId'],
      email: results['email'],
      name: results['name'],
      nickname: results['nickname'],
      phone: results['phone'],
      birthDt: results['birthDt'],
      experience: results['experience'],
      avatarUrl: results['avatarUrl'],
      notificationAgreed: results['notificationAgreed'],
    );
  }
}

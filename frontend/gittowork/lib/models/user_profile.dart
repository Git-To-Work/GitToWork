class UserProfile {
  final int userId;
  final String? email;
  final String name;
  final String nickname;
  final String phone;
  final String birthDt;
  final int experience;
  final String avatarUrl;
  final List<String> interestFields;

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
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as int,
      email: json['email'] as String?,
      name: json['name'] as String,
      nickname: json['nickname'] as String,
      phone: json['phone'] as String,
      birthDt: json['birthDt'] as String,
      experience: json['experience'] as int,
      avatarUrl: json['avatarUrl'] as String,
      interestFields: (json['interestFields'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
    );
  }
}

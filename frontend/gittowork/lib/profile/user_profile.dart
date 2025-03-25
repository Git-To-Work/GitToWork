// user_profile.dart
class UserProfile {
  final int userId;
  final String email;
  final String name;
  final String nickname;
  final String phone;
  final String dateOfBirth;
  final int experiment;
  final String avatarUrl;
  final List<String> interestFields;

  UserProfile({
    required this.userId,
    required this.email,
    required this.name,
    required this.nickname,
    required this.phone,
    required this.dateOfBirth,
    required this.experiment,
    required this.avatarUrl,
    required this.interestFields,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String,
      phone: json['phone'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      experiment: json['experiment'] as int,
      avatarUrl: json['avatarUrl'] as String,
      interestFields: (json['interestFields'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
    );
  }
}

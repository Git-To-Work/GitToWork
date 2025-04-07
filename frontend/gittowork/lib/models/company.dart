// models/company.dart

class Company {
  final int companyId;
  final String name;
  final String description; // 본문에 따라 fieldName 등을 추가로 둬도 됩니다.
  bool scrapped;
  bool hasActiveJobNotice;
  final List<String> techStacks;

  Company({
    required this.companyId,
    required this.name,
    required this.description,
    required this.scrapped,
    required this.hasActiveJobNotice,
    required this.techStacks,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      companyId: json['companyId'] as int,
      name: json['companyName'] as String,
      description: json['fieldName'] ?? '', // 예시
      scrapped: json['scrapped'] == true,
      hasActiveJobNotice: json['hasActiveJobNotice'] == true,
      techStacks: (json['techStacks'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }
}

// model/company.dart

class Company {
  final int id;
  final String name;
  final String description;
  final String? logoUrl;

  Company({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logoUrl'] as String?,
    );
  }
}

class InterestField {
  final List<String> interestFieldNames;
  final List<int> interestFieldIds;

  InterestField({
    required this.interestFieldNames,
    required this.interestFieldIds,
  });

  factory InterestField.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as Map<String, dynamic>?;
    if (results == null) {
      // 혹시라도 null 로 넘어오는 경우 방어로직
      return InterestField(interestFieldNames: [], interestFieldIds: []);
    }

    return InterestField(
      interestFieldNames: List<String>.from(results['interestsFields'] ?? []),
      interestFieldIds: List<int>.from(results['interestsFieldIds'] ?? []),
    );
  }
}

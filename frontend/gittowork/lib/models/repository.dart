/// 나의 레포지토리
class Repository {
  final int repoId;
  final String repoName;

  Repository({
    required this.repoId,
    required this.repoName,
  });

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      repoId: json['repoId'] as int,
      repoName: json['repoName'] as String,
    );
  }
}

/// 조합 레포지토리
class RepositoryCombination {
  final String selectedRepositoryId;
  final List<String> repositoryNames;

  RepositoryCombination({
    required this.selectedRepositoryId,
    required this.repositoryNames,
  });

  factory RepositoryCombination.fromJson(Map<String, dynamic> json) {
    return RepositoryCombination(
      selectedRepositoryId: json['selectedRepositoryId'] as String,
      repositoryNames: (json['repositoryNames'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// 분석 레포지토리
class RepositoryAnalysisResponse {
  final bool analysisStarted;
  final String message;

  RepositoryAnalysisResponse({
    required this.analysisStarted,
    required this.message,
  });

  factory RepositoryAnalysisResponse.fromJson(Map<String, dynamic> json) {
    final results = json['results'] ?? {};
    return RepositoryAnalysisResponse(
      analysisStarted: results['analysisStarted'] as bool,
      message: results['message'] as String,
    );
  }
}

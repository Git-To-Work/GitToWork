package com.gittowork.domain.github.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gittowork.domain.github.dto.response.GetMyRepositoryCombinationResponse;
import com.gittowork.domain.github.dto.response.GetMyRepositoryResponse;
import com.gittowork.domain.github.dto.response.Repo;
import com.gittowork.domain.github.entity.*;
import com.gittowork.domain.github.model.analysis.Stats;
import com.gittowork.domain.github.model.commit.Commit;
import com.gittowork.domain.github.model.repository.Repository;
import com.gittowork.domain.github.model.analysis.RepositoryResult;
import com.gittowork.domain.github.model.sonar.Measure;
import com.gittowork.domain.github.model.sonar.MeasuresResponse;
import com.gittowork.domain.github.model.sonar.SonarResponse;
import com.gittowork.domain.github.repository.*;
import com.gittowork.domain.user.entity.User;
import com.gittowork.domain.user.repository.UserRepository;
import com.gittowork.global.exception.GithubRepositoryNotFoundException;
import com.gittowork.global.exception.SonarAnalysisException;
import com.gittowork.global.exception.UserNotFoundException;
import com.gittowork.global.response.MessageOnlyResponse;
import com.gittowork.global.service.GithubRestApiService;
import lombok.extern.slf4j.Slf4j;
import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.errors.GitAPIException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
public class GithubService {

    private final GithubAnalysisResultRepository githubAnalysisResultRepository;
    private final GithubCommitRepository githubCommitRepository;
    private final GithubPullRequestRepository githubPullRequestRepository;
    private final GithubIssueRepository githubIssueRepository;
    @Value("${sonar.host.url}")
    private String sonarHostUrl;

    @Value("${sonar.login.token}")
    private String sonarLoginToken;

    private final GithubRepoRepository githubRepoRepository;
    private final UserRepository userRepository;
    private final SelectedRepoRepository selectedRepoRepository;
    private final GithubRestApiService githubRestApiService;
    private final RestTemplate restTemplate;

    @Autowired
    public GithubService(GithubRepoRepository githubRepoRepository,
                         UserRepository userRepository,
                         SelectedRepoRepository selectedRepoRepository,
                         GithubRestApiService githubRestApiService,
                         RestTemplate restTemplate, GithubAnalysisResultRepository githubAnalysisResultRepository, GithubCommitRepository githubCommitRepository, GithubPullRequestRepository githubPullRequestRepository, GithubIssueRepository githubIssueRepository) {
        this.githubRepoRepository = githubRepoRepository;
        this.userRepository = userRepository;
        this.selectedRepoRepository = selectedRepoRepository;
        this.githubRestApiService = githubRestApiService;
        this.restTemplate = restTemplate;
        this.githubAnalysisResultRepository = githubAnalysisResultRepository;
        this.githubCommitRepository = githubCommitRepository;
        this.githubPullRequestRepository = githubPullRequestRepository;
        this.githubIssueRepository = githubIssueRepository;
    }

    /**
     * 1. 메서드 설명: 선택된 GitHub repository 정보를 저장하는 API.
     * 2. 로직:
     *    - SecurityContext에서 현재 인증된 사용자의 username을 조회한다.
     *    - username을 이용해 User 엔티티를 검색하여 사용자 정보를 가져온다.
     *    - 조회된 User 엔티티의 id를 사용해 GithubRepository 엔티티를 조회한다.
     *    - 전달받은 repository ID 배열을 Set으로 변환한 후, GithubRepository에 저장된 repository 목록 중 선택된 항목을 필터링한다.
     *    - 필터링된 repository 리스트와 userId를 바탕으로 SelectedRepository 엔티티를 생성 또는 갱신하고 저장한다.
     * 3. param: selectedGithubRepositoryIds - 사용자가 선택한 repository의 ID 배열.
     * 4. return: 성공 시 "레포지토리 선택 저장 요청 처리 완료" 메시지를 포함한 MessageOnlyResponse 객체.
     */
    @Transactional
    public MessageOnlyResponse saveSelectedGithubRepository(int[] selectedGithubRepositoryIds) {
        String username = getUserName();

        User user = userRepository.findByGithubName(username)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        int userId = user.getId();

        GithubRepository githubRepository = githubRepoRepository.findByUserId(userId)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

        Set<Integer> selectedIds = Arrays.stream(selectedGithubRepositoryIds)
                .boxed()
                .collect(Collectors.toSet());

        List<Repository> selectedRepositories = githubRepository.getRepositories().stream()
                .filter(repo -> selectedIds.contains(repo.getRepoId()))
                .collect(Collectors.toList());

        SelectedRepository selectedRepository = findMatchingSelectedRepository(userId, selectedRepositories)
                .map(existing -> {
                    existing.setRepositories(selectedRepositories);
                    return existing;
                })
                .orElseGet(() -> SelectedRepository.builder()
                        .userId(userId)
                        .repositories(selectedRepositories)
                        .build());

        selectedRepoRepository.save(selectedRepository);

        return MessageOnlyResponse.builder()
                .message("레포지토리 선택 저장 요청 처리 완료")
                .build();
    }

    /**
     * 1. 메서드 설명: 지정된 userId와 선택된 repository 리스트를 기반으로 기존에 저장된 SelectedRepository 엔티티 중 동일한 것을 찾는 메서드.
     * 2. 로직:
     *    - userId를 기준으로 해당 사용자의 모든 SelectedRepository 엔티티를 조회한다.
     *    - 각 SelectedRepository 엔티티에 대해, 저장된 repository 리스트의 크기가 선택된 repository 리스트와 동일하며,
     *      저장된 repository 집합이 선택된 repository 집합을 모두 포함하는지 검사한다.
     * 3. param:
     *      - userId: 사용자 식별자.
     *      - selectedRepositories: 필터링된 선택 repository 리스트.
     * 4. return: 동일한 repository 정보가 존재하면 Optional로 해당 SelectedRepository를 반환, 그렇지 않으면 Optional.empty() 반환.
     */
    private Optional<SelectedRepository> findMatchingSelectedRepository(int userId, List<Repository> selectedRepositories) {
        List<SelectedRepository> existingSelectedRepos = selectedRepoRepository.findAllByUserId(userId);
        return existingSelectedRepos.stream()
                .filter(existing -> existing.getRepositories().size() == selectedRepositories.size()
                        && new HashSet<>(existing.getRepositories()).containsAll(selectedRepositories))
                .findFirst();
    }

    /**
     * 1. 메서드 설명: 현재 인증된 사용자의 GitHub 저장소 정보를 조회하여, 해당 정보를 GetMyRepositoryResponse DTO로 반환하는 API.
     * 2. 로직:
     *    - 현재 인증된 사용자의 username을 조회한다.
     *    - username을 기반으로 User 엔티티를 검색한다.
     *    - User 엔티티의 id를 사용하여 GithubRepository 엔티티를 조회한다.
     *    - 조회된 GithubRepository의 repositories 리스트를 Repo DTO로 변환한다.
     *    - 변환된 Repo DTO 리스트를 포함하는 GetMyRepositoryResponse 객체를 반환한다.
     * 3. param: 없음.
     * 4. return: 사용자의 GitHub 저장소 정보를 담은 GetMyRepositoryResponse 객체.
     */
    public GetMyRepositoryResponse getMyRepository() {
        String username = getUserName();

        User user = userRepository.findByGithubName(username)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        int userId = user.getId();

        GithubRepository githubRepository = githubRepoRepository.findByUserId(userId)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

        List<Repo> repos = githubRepository.getRepositories().stream()
                .map(repo -> Repo.builder()
                        .repoId(repo.getRepoId())
                        .repoName(repo.getRepoName())
                        .build())
                .collect(Collectors.toList());

        return GetMyRepositoryResponse.builder()
                .repositories(repos)
                .build();
    }

    /**
     * 1. 메서드 설명: 현재 인증된 사용자의 SelectedRepository 목록을 조회하여,
     *    각 SelectedRepository 내의 repository 리스트를 Repo DTO로 변환한 후,
     *    이를 조합하여 GetMyRepositoryCombinationResponse DTO로 반환하는 API.
     * 2. 로직:
     *    - 현재 인증된 사용자의 username을 조회한다.
     *    - username을 기반으로 User 엔티티를 검색하여 userId를 확보한다.
     *    - userId를 사용하여 SelectedRepository 리스트를 조회한다.
     *    - 각 SelectedRepository 객체의 repositories 리스트를 Repo DTO로 변환하여 List<List<Repo>> 형태로 조합한다.
     *    - 조합된 리스트를 포함하는 GetMyRepositoryCombinationResponse 객체를 반환한다.
     * 3. param: 없음.
     * 4. return: 변환된 repository 조합 정보를 담은 GetMyRepositoryCombinationResponse 객체.
     */
    public GetMyRepositoryCombinationResponse getMyRepositoryCombination() {
        String username = getUserName();

        User user = userRepository.findByGithubName(username)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        int userId = user.getId();

        List<SelectedRepository> selectedRepositories = selectedRepoRepository.findAllByUserId(userId);

        List<List<Repo>> repositoryCombinations = selectedRepositories.stream()
                .map(selectedRepo -> selectedRepo.getRepositories().stream()
                        .map(repo -> Repo.builder()
                                .repoId(repo.getRepoId())
                                .repoName(repo.getRepoName())
                                .build())
                        .collect(Collectors.toList()))
                .toList();

        return GetMyRepositoryCombinationResponse.builder()
                .repositoryCombinations(repositoryCombinations)
                .build();
    }

    /**
     * 1. 메서드 설명: GitHub API를 통해 사용자 관련 repository, commit, repository language, issues, pull requests, 코드 정보를 비동기적으로 조회 및 저장하는 메서드.
     * 2. 로직:
     *    - githubRestApiService의 메서드들을 호출하여 각 GitHub 관련 정보를 순차적으로 저장한다.
     *    - 각 저장 작업은 내부적으로 GitHub API와의 통신을 통해 데이터를 조회한 후 데이터베이스에 저장한다.
     *    - @Async 어노테이션이 적용되어 해당 메서드는 별도 쓰레드에서 실행되므로 호출 후 바로 리턴된다.
     * 3. param:
     *      accessToken - GitHub API 접근에 사용되는 access token.
     *      userName    - GitHub 사용자 이름.
     *      userId      - 로컬 사용자 식별자.
     * 4. return: 없음.
     */
    @Async
    public void saveUserGithubRepositoryInfo(String accessToken, String userName, int userId) {
        githubRestApiService.saveUserGithubRepository(accessToken, userName, userId);
        githubRestApiService.saveUserGithubCommits(accessToken, userName, userId);
        githubRestApiService.saveUserRepositoryLanguage(accessToken, userName, userId);
        githubRestApiService.saveGithubIssues(accessToken);
        githubRestApiService.saveGithubPullRequests(accessToken);
        githubRestApiService.checkNewGithubEvents(accessToken, userName, userId);

        log.info("{}: Github repository info saved", userName);
    }

    @Async
    public void analysisSelectedRepositories(int userId, int[] selectedRepositoryIds) {
        GithubRepository githubRepository = githubRepoRepository.findByUserId(userId)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

        List<Repository> allRepositories = githubRepository.getRepositories();

        List<Repository> selectedRepositories = new ArrayList<>();
        for (int selectedRepositoryId : selectedRepositoryIds) {
            for (Repository allRepository : allRepositories) {
                if (selectedRepositoryId == allRepository.getRepoId()) {
                    selectedRepositories.add(allRepository);
                }
            }
        }

        SelectedRepository selectedRepository = selectedRepoRepository.findByUserIdAndRepositories(userId, selectedRepositories)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

        List<RepositoryResult> repositoryResults = new ArrayList<>();
        for (Repository repository : selectedRepository.getRepositories()) {
            String repositoryPathUrl = "https://github.com/" + repository.getFullName() + ".git";
            try {
                File localRepo = cloneRepository(repositoryPathUrl);
                String projectKey = extractProjectKey(repositoryPathUrl);
                ProcessBuilder processBuilder = new ProcessBuilder(
                        "sonar-scanner",
                        "-Dsonar.projectKey=" + projectKey,
                        "-Dsonar.sources=" + localRepo.getAbsolutePath(),
                        "-Dsonar.host.url=" + sonarHostUrl,
                        "-Dsonar.login=" + sonarLoginToken
                );
                processBuilder.directory(localRepo);
                log.info("Starting sonar scanner for project {}, projectKey: {} ", repositoryPathUrl, projectKey);

                Process process = processBuilder.start();
                int exitCode = process.waitFor();
                if (exitCode != 0) {
                    log.error("sonar-scanner failed for project {} with code {}", repositoryPathUrl, exitCode);
                    throw new SonarAnalysisException("SonarQube analysis failed for project: " + repositoryPathUrl);
                }
                RepositoryResult result = pollAndParseAnalysisResult(projectKey, repository.getRepoId());
                log.info("Analysis result parsed for project {}", repositoryPathUrl);

                GithubCommit githubCommit = githubCommitRepository.findByRepoId(repository.getRepoId())
                        .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

                List<GithubPullRequest> githubPullRequests = githubPullRequestRepository.findAllByRepoId(repository.getRepoId())
                        .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

                List<GithubIssue> githubIssues = githubIssueRepository.findAllByRepoId(repository.getRepoId())
                        .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

                int totalCommitCnt = githubCommit.getCommits().size();
                int totalPRCnt = githubPullRequests.size();
                int totalIssueCnt = githubIssues.size();

                Stats stats = Stats.builder()
                        .stargazersCount(repository.getStargazersCount())
                        .commitCount(totalCommitCnt)
                        .prCount(totalPRCnt)
                        .issueCount(totalIssueCnt)
                        .build();

                result.setStats(stats);

                List<Commit> commits = githubCommit.getCommits();
                commits.sort(Comparator.comparing(Commit::getCommitDate).reversed());

                LocalDateTime latestDate = commits.get(0).getCommitDate();
                LocalDateTime oldestDate = commits.get(commits.size() - 1).getCommitDate();

                int daysDifference = (int) ChronoUnit.DAYS.between(oldestDate, latestDate);

                int commitFrequency = totalCommitCnt / daysDifference;

                repositoryResults.add(result);

                result.setCommitFrequency(commitFrequency);

            } catch (Exception e) {
                log.error("Exception while analyzing repository: {}", repositoryPathUrl, e);
                throw new SonarAnalysisException("SonarQube analysis failed: " + e.getMessage());
            }
        }

        // TODO: languageRatio 합산

        // TODO: overallScore 합산
        
        // TODO: ActivityMetrics 계산

        // TODO: primaryRole, roleScore, aiAnalysis GPT API 활용

        GithubAnalysisResult githubAnalysisResult = GithubAnalysisResult.builder()
                .userId(userId)
                .analysisDate(LocalDateTime.now())
                .selectedRepositoriesId(selectedRepository.getSelectedRepositoryId())
                .selectedRepositories(selectedRepository.getRepositories())
                .languageRatios(null)
                .repositories(repositoryResults)
                .overallScore(0)
                .primaryRole(null)
                .roleScores(null)
                .activityMetrics(null)
                .aiAnalysis(null)
                .build();

        githubAnalysisResultRepository.save(githubAnalysisResult);
    }

    private File cloneRepository(String repoUrl) {
        String projectKey = extractProjectKey(repoUrl);
        File repoDir = new File("/tmp/repositories/" + projectKey);
        if (!repoDir.exists()) {
            log.info("Cloning repository {} into {}", repoUrl, repoDir.getAbsolutePath());
            try {
                Git.cloneRepository()
                        .setURI(repoUrl)
                        .setDirectory(repoDir)
                        .call();
            } catch (GitAPIException e) {
                log.error("Error while cloning repository: {}", repoUrl, e);
                throw new SonarAnalysisException("Failed to clone repository: " + e.getMessage());
            }
        }
        return repoDir;
    }

    private String extractProjectKey(String repoUrl) {
        String[] parts = repoUrl.split("/");
        String org = parts[parts.length - 2];
        String project = parts[parts.length - 1].replace(".git", "");
        return org + "_" + project;
    }

    private RepositoryResult pollAndParseAnalysisResult(String projectKey, int repoId) throws InterruptedException {
        Map<String, Double> weights = new HashMap<>();
        weights.put("coverage", 20.0);
        weights.put("bugs", 40.0);
        weights.put("code_smells", 30.0);
        weights.put("vulnerabilities", 50.0);
        weights.put("duplicated_lines_density", 10.0);

        while (true) {
            SonarResponse sonarResponse = fetchAnalysisResult(projectKey);

            if (sonarResponse.isSuccessful()) {
                double totalPenalty = sonarResponse.getProjectStatus().getConditions().stream()
                        .mapToDouble(condition -> {
                            double weight = weights.getOrDefault(condition.getMetricKey(), 10.0);
                            if ("ERROR".equalsIgnoreCase(condition.getStatus())) {
                                try {
                                    double actual = Double.parseDouble(condition.getActualValue());
                                    double threshold = Double.parseDouble(condition.getErrorThreshold());
                                    double penaltyFactor = Math.min(actual / threshold, 1.0);
                                    return weight * penaltyFactor;
                                } catch (NumberFormatException e) {
                                    return weight;
                                }
                            }
                            return 0.0;
                        }).sum();
                int overallScore = (int) Math.max(0, 100 - totalPenalty);

                Map<String, Double> languageDistribution = fetchLanguageDistribution(projectKey);
                double totalLines = languageDistribution.values().stream().mapToDouble(Double::doubleValue).sum();
                Map<String, Double> languageRatios = new HashMap<>();
                if (totalLines > 0) {
                    languageRatios = languageDistribution.entrySet().stream()
                            .collect(Collectors.toMap(
                                    Map.Entry::getKey,
                                    e -> (e.getValue() / totalLines) * 100
                            ));
                }

                Map<String, String> projectMeasures = fetchProjectMeasures(projectKey);
                Map<String, Double> languageQualityScores = computeQualityScoreByLanguage(projectMeasures);

                return RepositoryResult.builder()
                        .repoId(repoId)
                        .score(overallScore)
                        .insights("Coverage: " + sonarResponse.getCoverage() +
                                "%, Bugs: " + sonarResponse.getBugCount())
                        .languages(languageRatios.entrySet().stream()
                                .collect(Collectors.toMap(
                                        Map.Entry::getKey,
                                        e -> e.getValue().intValue()
                                )))
                        .stats(null)
                        .commitFrequency(0)
                        .languageLevel(languageQualityScores)
                        .build();
            } else if (sonarResponse.isError()) {
                throw new SonarAnalysisException("SonarQube analysis returned error: " + sonarResponse.getErrorMessage());
            }
        }
    }

    private SonarResponse fetchAnalysisResult(String projectKey) {
        String url = sonarHostUrl + "/api/qualitygates/project_status?projectKey=" + projectKey;

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Basic " +
                Base64.getEncoder().encodeToString((sonarLoginToken + ":").getBytes()));
        HttpEntity<String> request = new HttpEntity<>(headers);

        ResponseEntity<SonarResponse> response = restTemplate.exchange(url, HttpMethod.GET, request, SonarResponse.class);
        return response.getBody();
    }

    private Map<String, Double> fetchLanguageDistribution(String projectKey) {
        String url = sonarHostUrl + "/api/measures/component?componentKey=" + projectKey +
                "&metricKeys=ncloc_language_distribution";

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Basic " +
                Base64.getEncoder().encodeToString((sonarLoginToken + ":").getBytes()));
        HttpEntity<String> request = new HttpEntity<>(headers);

        ResponseEntity<MeasuresResponse> response = restTemplate.exchange(url, HttpMethod.GET, request, MeasuresResponse.class);
        MeasuresResponse measuresResponse = response.getBody();

        if (measuresResponse != null && measuresResponse.getComponent() != null) {
            List<Measure> measures = measuresResponse.getComponent().getMeasures();
            for (Measure measure : measures) {
                if ("ncloc_language_distribution".equals(measure.getMetric())) {
                    String value = measure.getValue();
                    try {
                        ObjectMapper mapper = new ObjectMapper();
                        Map<String, String> tempMap = mapper.readValue(value, new TypeReference<Map<String, String>>() {});
                        Map<String, Double> languageDistribution = new HashMap<>();
                        for (Map.Entry<String, String> entry : tempMap.entrySet()) {
                            languageDistribution.put(entry.getKey(), Double.parseDouble(entry.getValue()));
                        }
                        return languageDistribution;
                    } catch (Exception e) {
                        log.error("Error parsing language distribution for projectKey {}: {}", projectKey, e.getMessage());
                        return Collections.emptyMap();
                    }
                }
            }
        }
        return Collections.emptyMap();
    }

    private Map<String, String> fetchProjectMeasures(String projectKey) {
        String metricKeys = "coverage,bugs,code_smells,vulnerabilities,duplicated_lines_density";
        String url = sonarHostUrl + "/api/measures/component?componentKey=" + projectKey + "&metricKeys=" + metricKeys;

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Basic " +
                Base64.getEncoder().encodeToString((sonarLoginToken + ":").getBytes()));
        HttpEntity<String> request = new HttpEntity<>(headers);

        ResponseEntity<MeasuresResponse> response = restTemplate.exchange(url, HttpMethod.GET, request, MeasuresResponse.class);
        MeasuresResponse measuresResponse = response.getBody();

        Map<String, String> measuresMap = new HashMap<>();
        if (measuresResponse != null && measuresResponse.getComponent() != null) {
            for (Measure measure : measuresResponse.getComponent().getMeasures()) {
                measuresMap.put(measure.getMetric(), measure.getValue());
            }
        }

        return measuresMap;
    }

    private Map<String, Double> computeQualityScoreByLanguage(Map<String, String> measuresMap) {
        Map<String, Map<String, Double>> languageMetrics = new HashMap<>();
        for (Map.Entry<String, String> entry : measuresMap.entrySet()) {
            String key = entry.getKey(); // 예: "coverage:Java"
            String valueStr = entry.getValue();
            String[] parts = key.split(":");

            if (parts.length == 2) {
                String metric = parts[0];
                String language = parts[1];
                double value = parseDoubleOrDefault(valueStr);
                languageMetrics.computeIfAbsent(language, k -> new HashMap<>()).put(metric, value);
            }
        }

        return getStringDoubleMap(languageMetrics);
    }

    private static Map<String, Double> getStringDoubleMap(Map<String, Map<String, Double>> languageMetrics) {
        Map<String, Double> languageQualityScores = new HashMap<>();
        for (Map.Entry<String, Map<String, Double>> entry : languageMetrics.entrySet()) {
            Map<String, Double> metrics = entry.getValue();

            double coverage = metrics.getOrDefault("coverage", 0.0);
            double bugs = metrics.getOrDefault("bugs", 0.0);
            double codeSmells = metrics.getOrDefault("code_smells", 0.0);
            double vulnerabilities = metrics.getOrDefault("vulnerabilities", 0.0);
            double duplicatedLinesDensity = metrics.getOrDefault("duplicated_lines_density", 0.0);

            double qualityScore = coverage - (bugs * 2 + codeSmells * 0.5 + vulnerabilities * 5 + duplicatedLinesDensity);
            languageQualityScores.put(entry.getKey(), qualityScore);
        }

        return languageQualityScores;
    }

    private double parseDoubleOrDefault(String value) {
        try {
            return value != null ? Double.parseDouble(value) : 0.0;
        } catch (NumberFormatException e) {
            return 0.0;
        }
    }

    /**
     * 1. 메서드 설명: 현재 SecurityContextHolder에서 username을 추출하는 헬퍼 메서드.
     * 2. 로직:
     *    - SecurityContextHolder에서 현재 인증 정보를 조회하여 username을 반환한다.
     * 3. param: 없음.
     * 4. return: 현재 인증된 사용자의 username 문자열.
     */
    private String getUserName() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }
}

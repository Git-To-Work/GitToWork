package com.gittowork.domain.github.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gittowork.domain.github.entity.*;
import com.gittowork.domain.github.model.analysis.ActivityMetrics;
import com.gittowork.domain.github.model.analysis.RepositoryResult;
import com.gittowork.domain.github.model.analysis.Stats;
import com.gittowork.domain.github.model.commit.Commit;
import com.gittowork.domain.github.model.repository.Repository;
import com.gittowork.domain.github.model.sonar.Measure;
import com.gittowork.domain.github.model.sonar.MeasuresResponse;
import com.gittowork.domain.github.model.sonar.SonarResponse;
import com.gittowork.domain.github.repository.*;
import com.gittowork.domain.user.entity.User;
import com.gittowork.domain.user.repository.UserRepository;
import com.gittowork.global.exception.GithubAnalysisException;
import com.gittowork.global.exception.GithubRepositoryNotFoundException;
import com.gittowork.global.exception.SonarAnalysisException;
import com.gittowork.global.exception.UserNotFoundException;
import com.gittowork.global.service.GithubRestApiService;
import com.gittowork.global.service.GptService;
import lombok.extern.slf4j.Slf4j;
import lombok.RequiredArgsConstructor;
import org.eclipse.jgit.api.Git;
import org.eclipse.jgit.api.errors.GitAPIException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class GithubAnalysisService {

    @Value("${sonar.host.url}")
    private String sonarHostUrl;

    @Value("${sonar.login.token}")
    private String sonarLoginToken;

    private final UserRepository userRepository;
    private final GithubRestApiService githubRestApiService;
    private final GithubRepoRepository githubRepoRepository;
    private final SelectedRepoRepository selectedRepoRepository;
    private final GptService gptService;
    private final GithubAnalysisResultRepository githubAnalysisResultRepository;
    private final GithubCommitRepository githubCommitRepository;
    private final GithubPullRequestRepository githubPullRequestRepository;
    private final GithubIssueRepository githubIssueRepository;
    private final RestTemplate restTemplate;


    /**
     * 1. 메서드 설명: 비동기로 선택된 repository에 대해 GitHub 분석을 수행하는 API.
     * 2. 로직:
     *    - username을 기반으로 User 엔티티를 조회하여 userId를 확보한다.
     *    - 확보한 userId와 선택된 repository 배열을 사용하여 분석 로직을 수행한다.
     * 3. param:
     *      int[] selectedRepositories - 분석 대상 repository의 repoId 배열.
     *      String userName - 현재 인증된 사용자의 username.
     * 4. return: 없음 (비동기 작업 수행).
     */
    @Async
    public void githubAnalysisByRepository(int[] selectedRepositories, String userName) {
        User user = userRepository.findByGithubName(userName)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        analysisSelectedRepositories(user.getId(), selectedRepositories);
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
        GithubRepository userGithubRepository = githubRestApiService.saveUserGithubRepository(accessToken, userName, userId);
        githubRestApiService.saveUserGithubCommits(accessToken, userName, userId);
        githubRestApiService.saveUserRepositoryLanguage(accessToken, userName, userId);
        githubRestApiService.saveGithubIssues(accessToken, userName, userId);
        githubRestApiService.saveGithubPullRequests(accessToken, userName, userId);
        githubRestApiService.checkNewGithubEvents(accessToken, userName, userId, userGithubRepository.getRepositories().stream()
                .map(Repository::getRepoName)
                .collect(Collectors.toList()));
        log.info("{}: Github repository info saved", userName);
    }

    /**
     * 1. 메서드 설명: GitHub API를 통해 선택된 repository들을 분석하고, SonarQube 및 GitHub 관련 정보를 조회하여 분석 결과를 저장하는 비동기 메서드.
     * 2. 로직:
     *    - 사용자와 연결된 GitHub repository 정보를 조회 후, 선택된 repository들로 필터링한다.
     *    - 각 repository별로 SonarQube 분석과 GitHub commit, pull request, issue 정보를 조회하여 RepositoryResult 객체를 생성한다.
     *    - 전체 언어 비율, 점수, star, commit, PR, issue 합계를 계산하고, ActivityMetrics 및 GithubAnalysisResult를 생성한다.
     *    - GPT 서비스를 통해 추가 분석 후 최종 분석 결과를 데이터베이스에 저장한다.
     * 3. param:
     *      userId - 로컬 사용자 식별자.
     *      selectedRepositoryIds - 선택된 repository들의 식별자 배열.
     * 4. return: 없음.
     */
    private void analysisSelectedRepositories(int userId, int[] selectedRepositoryIds) {
        GithubRepository githubRepository = githubRepoRepository.findByUserId(userId)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

        List<Repository> selectedRepositories = githubRepository.getRepositories().stream()
                .filter(repo -> Arrays.stream(selectedRepositoryIds).anyMatch(id -> id == repo.getRepoId()))
                .collect(Collectors.toList());

        SelectedRepository selectedRepository = selectedRepoRepository.findByUserIdAndRepositories(userId, selectedRepositories)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

        Map<String, Integer> totalLanguageRatio = new HashMap<>();
        AtomicInteger totalOverallScore = new AtomicInteger(0);
        AtomicInteger totalStars = new AtomicInteger(0);
        AtomicInteger totalCommits = new AtomicInteger(0);
        AtomicInteger totalPRs = new AtomicInteger(0);
        AtomicInteger totalIssues = new AtomicInteger(0);

        List<RepositoryResult> repositoryResults = selectedRepository.getRepositories().stream()
                .map(repo -> processRepository(repo, totalLanguageRatio, totalOverallScore, totalStars, totalCommits, totalPRs, totalIssues))
                .collect(Collectors.toList());

        int totalLines = totalLanguageRatio.values().stream().mapToInt(Integer::intValue).sum();
        Map<String, Double> languagePercentages = totalLanguageRatio.entrySet().stream()
                .collect(Collectors.toMap(
                        Map.Entry::getKey,
                        entry -> totalLines > 0 ? (entry.getValue() * 100.0 / totalLines) : 0.0
                ));

        int overallScoreMean = selectedRepository.getRepositories().isEmpty() ? 0 :
                totalOverallScore.get() / selectedRepository.getRepositories().size();

        ActivityMetrics activityMetrics = ActivityMetrics.builder()
                .totalStars(totalStars.get())
                .totalCommits(totalCommits.get())
                .totalPRs(totalPRs.get())
                .totalIssues(totalIssues.get())
                .build();

        GithubAnalysisResult githubAnalysisResult = GithubAnalysisResult.builder()
                .userId(userId)
                .analysisDate(LocalDateTime.now())
                .selectedRepositoriesId(selectedRepository.getSelectedRepositoryId())
                .selectedRepositories(selectedRepository.getRepositories())
                .languageRatios(languagePercentages)
                .repositories(repositoryResults)
                .overallScore(overallScoreMean)
                .primaryRole(null)
                .roleScores(null)
                .activityMetrics(activityMetrics)
                .aiAnalysis(null)
                .build();

        try {
            GithubAnalysisResult gptAnalysisResult = gptService.githubDataAnalysis(githubAnalysisResult, 500);
            githubAnalysisResult.setPrimaryRole(gptAnalysisResult.getPrimaryRole());
            githubAnalysisResult.setRoleScores(gptAnalysisResult.getRoleScores());
            githubAnalysisResult.setAiAnalysis(gptAnalysisResult.getAiAnalysis());
        } catch (JsonProcessingException e) {
            throw new GithubAnalysisException("Github analysis failed" + e.getMessage());
        }
        githubAnalysisResultRepository.save(githubAnalysisResult);
    }

    /**
     * 1. 메서드 설명: 단일 repository에 대해 SonarQube 분석과 GitHub 관련 정보를 조회하여 RepositoryResult 객체를 생성하는 메서드.
     * 2. 로직:
     *    - repository를 클론한 후, SonarQube 스캐너를 실행하여 분석 결과를 조회한다.
     *    - GitHub commit, pull request, issue 정보를 조회하여 Stats 객체를 생성하고 RepositoryResult에 설정한다.
     *    - commit 날짜를 기반으로 commit 빈도를 계산하고, 언어별 비율을 누적 통계에 반영한다.
     * 3. param:
     *      repository - 분석 대상 repository.
     *      totalLanguageRatio - 전체 언어 비율 통계가 저장되는 Map.
     *      totalOverallScore - 전체 점수를 누적하는 AtomicInteger.
     *      totalStars - 전체 star 수를 누적하는 AtomicInteger.
     *      totalCommits - 전체 commit 수를 누적하는 AtomicInteger.
     *      totalPRs - 전체 pull request 수를 누적하는 AtomicInteger.
     *      totalIssues - 전체 issue 수를 누적하는 AtomicInteger.
     * 4. return: RepositoryResult 객체.
     */
    private RepositoryResult processRepository(Repository repository,
                                               Map<String, Integer> totalLanguageRatio,
                                               AtomicInteger totalOverallScore,
                                               AtomicInteger totalStars,
                                               AtomicInteger totalCommits,
                                               AtomicInteger totalPRs,
                                               AtomicInteger totalIssues) {
        String repositoryPathUrl = "https://github.com/" + repository.getFullName() + ".git";
        try {
            File localRepo = cloneRepository(repositoryPathUrl);
            String projectKey = extractProjectKey(repositoryPathUrl);

            ProcessBuilder processBuilder = new ProcessBuilder(
                    "sonar-scanner",
                    "-X",
                    "-Dsonar.projectKey=" + projectKey,
                    "-Dsonar.sources=" + localRepo.getAbsolutePath(),
                    "-Dsonar.host.url=" + sonarHostUrl,
                    "-Dsonar.login=" + sonarLoginToken
            );
            processBuilder.directory(localRepo);
            Process process = processBuilder.start();
            BufferedReader stdOut = new BufferedReader(new InputStreamReader(process.getInputStream()));
            BufferedReader stdErr = new BufferedReader(new InputStreamReader(process.getErrorStream()));
            String s;
            while ((s = stdOut.readLine()) != null) {
                log.info(s);
            }
            while ((s = stdErr.readLine()) != null) {
                log.error(s);
            }
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                throw new SonarAnalysisException("SonarQube analysis failed for project: " + repositoryPathUrl);
            }
            RepositoryResult result = pollAndParseAnalysisResult(projectKey, repository.getRepoId());

            GithubCommit githubCommit = githubCommitRepository.findByRepoId(repository.getRepoId())
                    .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));
            List<GithubPullRequest> githubPullRequests = githubPullRequestRepository.findAllByRepoId(repository.getRepoId())
                    .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));
            List<GithubIssue> githubIssues = githubIssueRepository.findAllByRepoId(repository.getRepoId())
                    .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

            int commitCount = githubCommit.getCommits().size();
            int prCount = githubPullRequests.size();
            int issueCount = githubIssues.size();

            Stats stats = Stats.builder()
                    .stargazersCount(repository.getStargazersCount())
                    .commitCount(commitCount)
                    .prCount(prCount)
                    .issueCount(issueCount)
                    .build();
            result.setStats(stats);

            List<Commit> commits = githubCommit.getCommits();
            commits.sort(Comparator.comparing(Commit::getCommitDate).reversed());
            LocalDateTime latestDate = commits.get(0).getCommitDate();
            LocalDateTime oldestDate = commits.get(commits.size() - 1).getCommitDate();
            int daysDifference = (int) ChronoUnit.DAYS.between(oldestDate, latestDate);
            int commitFrequency = daysDifference > 0 ? commitCount / daysDifference : commitCount;
            result.setCommitFrequency(commitFrequency);

            result.getLanguages().forEach((lang, count) ->
                    totalLanguageRatio.merge(lang, count, Integer::sum)
            );

            totalOverallScore.addAndGet(result.getScore());
            totalStars.addAndGet(repository.getStargazersCount());
            totalCommits.addAndGet(commitCount);
            totalPRs.addAndGet(prCount);
            totalIssues.addAndGet(issueCount);
            return result;
        } catch (Exception e) {
            log.error("Exception while analyzing repository: {}", repositoryPathUrl, e);
            throw new SonarAnalysisException("SonarQube analysis failed: " + e.getMessage());
        }
    }

    /**
     * 1. 메서드 설명: 주어진 repository URL로부터 로컬에 repository를 클론하는 메서드.
     * 2. 로직:
     *    - 지정된 디렉토리에 repository가 존재하지 않을 경우, Git 클라이언트를 이용해 클론한다.
     * 3. param:
     *      repoUrl - 클론할 repository의 URL.
     * 4. return: 클론된 로컬 repository의 File 객체.
     */
    private File cloneRepository(String repoUrl) {
        String projectKey = extractProjectKey(repoUrl);
        File repoDir = new File("tmp/repositories/" + projectKey);
        if (!repoDir.exists()) {
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

    /**
     * 1. 메서드 설명: repository URL에서 organization과 project 이름을 추출하여 프로젝트 키를 생성하는 메서드.
     * 2. 로직:
     *    - URL을 "/"로 분리한 후, organization과 project 이름을 조합하여 프로젝트 키를 생성한다.
     * 3. param:
     *      repoUrl - repository의 URL.
     * 4. return: 생성된 프로젝트 키.
     */
    private String extractProjectKey(String repoUrl) {
        String[] parts = repoUrl.split("/");
        String org = parts[parts.length - 2];
        String project = parts[parts.length - 1].replace(".git", "");
        return org + "_" + project;
    }

    /**
     * 1. 메서드 설명: SonarQube로부터 프로젝트 분석 결과를 폴링하고 파싱하여 RepositoryResult 객체를 생성하는 메서드.
     * 2. 로직:
     *    - SonarQube API를 반복 호출하여 분석 결과가 준비될 때까지 대기한다.
     *    - 프로젝트 상태와 조건들을 기반으로 총 페널티를 계산하고 점수를 산출한다.
     *    - 언어 분포 및 품질 점수를 추가로 계산하여 RepositoryResult 객체를 빌더 패턴으로 생성한다.
     * 3. param:
     *      projectKey - SonarQube 프로젝트 키.
     *      repoId - repository 식별자.
     * 4. return: RepositoryResult 객체.
     */
    private RepositoryResult pollAndParseAnalysisResult(String projectKey, int repoId) {
        Map<String, Double> weights = Map.of(
                "coverage", 20.0,
                "bugs", 40.0,
                "code_smells", 30.0,
                "vulnerabilities", 50.0,
                "duplicated_lines_density", 10.0
        );
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
                                    return weight * Math.min(actual / threshold, 1.0);
                                } catch (NumberFormatException e) {
                                    return weight;
                                }
                            }
                            return 0.0;
                        }).sum();
                int overallScore = (int) Math.max(0, 100 - totalPenalty);
                Map<String, Double> languageDistribution = fetchLanguageDistribution(projectKey);
                Map<String, Integer> languageDistributionInt = languageDistribution.entrySet().stream()
                        .collect(Collectors.toMap(Map.Entry::getKey, entry -> entry.getValue().intValue()));
                Map<String, String> projectMeasures = fetchProjectMeasures(projectKey);
                Map<String, Double> languageQualityScores = computeQualityScoreByLanguage(projectMeasures);
                return RepositoryResult.builder()
                        .repoId(repoId)
                        .score(overallScore)
                        .insights("Coverage: " + sonarResponse.getCoverage() + "%, Bugs: " + sonarResponse.getBugCount())
                        .languages(languageDistributionInt)
                        .stats(null)
                        .commitFrequency(0)
                        .languageLevel(languageQualityScores)
                        .build();
            } else if (sonarResponse.isError()) {
                throw new SonarAnalysisException("SonarQube analysis returned error: " + sonarResponse.getErrorMessage());
            }
        }
    }

    /**
     * 1. 메서드 설명: SonarQube API를 호출하여 프로젝트 분석 결과를 조회하는 메서드.
     * 2. 로직:
     *    - 주어진 프로젝트 키를 기반으로 SonarQube API URL을 생성하고, 인증 헤더를 포함한 GET 요청을 수행한다.
     * 3. param:
     *      projectKey - SonarQube 프로젝트 키.
     * 4. return: SonarResponse 객체.
     */
    private SonarResponse fetchAnalysisResult(String projectKey) {
        String url = sonarHostUrl + "/api/qualitygates/project_status?projectKey=" + projectKey;
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Basic " + Base64.getEncoder().encodeToString((sonarLoginToken + ":").getBytes()));
        HttpEntity<String> request = new HttpEntity<>(headers);
        ResponseEntity<SonarResponse> response = restTemplate.exchange(url, HttpMethod.GET, request, SonarResponse.class);
        return response.getBody();
    }

    /**
     * 1. 메서드 설명: SonarQube API를 호출하여 프로젝트의 언어 분포 정보를 조회하는 메서드.
     * 2. 로직:
     *    - 지정된 metric(ncloc_language_distribution)에 대한 값을 조회하여 JSON 문자열을 파싱한 후 Map으로 변환한다.
     * 3. param:
     *      projectKey - SonarQube 프로젝트 키.
     * 4. return: 언어별 라인 수 분포를 나타내는 Map.
     */
    private Map<String, Double> fetchLanguageDistribution(String projectKey) {
        String url = sonarHostUrl + "/api/measures/component?componentKey=" + projectKey + "&metricKeys=ncloc_language_distribution";
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Basic " + Base64.getEncoder().encodeToString((sonarLoginToken + ":").getBytes()));
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
                        tempMap.forEach((key, val) -> languageDistribution.put(key, Double.parseDouble(val)));
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

    /**
     * 1. 메서드 설명: SonarQube API를 호출하여 프로젝트의 주요 측정 지표들을 조회하는 메서드.
     * 2. 로직:
     *    - 지정된 metricKeys(coverage, bugs, code_smells, vulnerabilities, duplicated_lines_density)에 대해 값을 조회한 후 Map으로 변환한다.
     * 3. param:
     *      projectKey - SonarQube 프로젝트 키.
     * 4. return: 측정 지표를 나타내는 Map.
     */
    private Map<String, String> fetchProjectMeasures(String projectKey) {
        String metricKeys = "coverage,bugs,code_smells,vulnerabilities,duplicated_lines_density";
        String url = sonarHostUrl + "/api/measures/component?componentKey=" + projectKey + "&metricKeys=" + metricKeys;
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Basic " + Base64.getEncoder().encodeToString((sonarLoginToken + ":").getBytes()));
        HttpEntity<String> request = new HttpEntity<>(headers);
        ResponseEntity<MeasuresResponse> response = restTemplate.exchange(url, HttpMethod.GET, request, MeasuresResponse.class);
        MeasuresResponse measuresResponse = response.getBody();
        Map<String, String> measuresMap = new HashMap<>();
        if (measuresResponse != null && measuresResponse.getComponent() != null) {
            measuresResponse.getComponent().getMeasures().forEach(measure ->
                    measuresMap.put(measure.getMetric(), measure.getValue())
            );
        }
        return measuresMap;
    }

    /**
     * 1. 메서드 설명: 프로젝트 측정 지표를 기반으로 각 언어별 코드 품질 점수를 계산하는 메서드.
     * 2. 로직:
     *    - 측정 지표의 key를 ":"로 분리하여 metric과 언어를 구분하고, 해당 값을 기반으로 각 언어의 점수를 산출한다.
     * 3. param:
     *      measuresMap - 프로젝트 측정 지표를 담고 있는 Map.
     * 4. return: 언어별 품질 점수를 나타내는 Map.
     */
    private Map<String, Double> computeQualityScoreByLanguage(Map<String, String> measuresMap) {
        Map<String, Map<String, Double>> languageMetrics = new HashMap<>();
        measuresMap.forEach((key, valueStr) -> {
            String[] parts = key.split(":");
            if (parts.length == 2) {
                String metric = parts[0];
                String language = parts[1];
                double value = parseDoubleOrDefault(valueStr);
                languageMetrics.computeIfAbsent(language, k -> new HashMap<>()).put(metric, value);
            }
        });
        return getStringDoubleMap(languageMetrics);
    }

    /**
     * 1. 메서드 설명: 언어별 측정 지표 Map을 기반으로 각 언어의 최종 품질 점수를 계산하여 반환하는 메서드.
     * 2. 로직:
     *    - 각 언어에 대해 coverage, bugs, code_smells, vulnerabilities, duplicated_lines_density 값을 이용해 품질 점수를 산출한다.
     * 3. param:
     *      languageMetrics - 언어별로 metric과 값이 저장된 Map.
     * 4. return: 언어별 품질 점수를 나타내는 Map.
     */
    private static Map<String, Double> getStringDoubleMap(Map<String, Map<String, Double>> languageMetrics) {
        Map<String, Double> languageQualityScores = new HashMap<>();
        languageMetrics.forEach((language, metrics) -> {
            double coverage = metrics.getOrDefault("coverage", 0.0);
            double bugs = metrics.getOrDefault("bugs", 0.0);
            double codeSmells = metrics.getOrDefault("code_smells", 0.0);
            double vulnerabilities = metrics.getOrDefault("vulnerabilities", 0.0);
            double duplicatedLinesDensity = metrics.getOrDefault("duplicated_lines_density", 0.0);
            double qualityScore = coverage - (bugs * 2 + codeSmells * 0.5 + vulnerabilities * 5 + duplicatedLinesDensity);
            languageQualityScores.put(language, qualityScore);
        });
        return languageQualityScores;
    }

    /**
     * 1. 메서드 설명: 문자열을 double로 파싱하며, 파싱에 실패할 경우 기본값 0.0을 반환하는 메서드.
     * 2. 로직:
     *    - 문자열이 null이 아니면 double로 파싱하고, NumberFormatException 발생 시 0.0을 반환한다.
     * 3. param:
     *      value - 파싱할 문자열.
     * 4. return: 파싱된 double 값 또는 0.0.
     */
    private double parseDoubleOrDefault(String value) {
        try {
            return value != null ? Double.parseDouble(value) : 0.0;
        } catch (NumberFormatException e) {
            return 0.0;
        }
    }
}

package com.gittowork.domain.github.service;

import com.gittowork.domain.github.dto.response.GetMyRepositoryCombinationResponse;
import com.gittowork.domain.github.dto.response.GetMyRepositoryResponse;
import com.gittowork.domain.github.dto.response.Repo;
import com.gittowork.domain.github.entity.GithubAnalysisResult;
import com.gittowork.domain.github.entity.GithubRepository;
import com.gittowork.domain.github.entity.Repository;
import com.gittowork.domain.github.entity.SelectedRepository;
import com.gittowork.domain.github.repository.GithubAnalysisResultRepository;
import com.gittowork.domain.github.repository.GithubRepoRepository;
import com.gittowork.domain.github.repository.SelectedRepoRepository;
import com.gittowork.domain.user.entity.User;
import com.gittowork.domain.user.repository.UserRepository;
import com.gittowork.global.exception.GithubRepositoryNotFoundException;
import com.gittowork.global.exception.SonarAnalysisException;
import com.gittowork.global.exception.UserNotFoundException;
import com.gittowork.global.response.MessageOnlyResponse;
import com.gittowork.global.service.GithubRestApiService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.File;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
public class GithubService {

    private final GithubAnalysisResultRepository githubAnalysisResultRepository;
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
                         RestTemplate restTemplate, GithubAnalysisResultRepository githubAnalysisResultRepository) {
        this.githubRepoRepository = githubRepoRepository;
        this.userRepository = userRepository;
        this.selectedRepoRepository = selectedRepoRepository;
        this.githubRestApiService = githubRestApiService;
        this.restTemplate = restTemplate;
        this.githubAnalysisResultRepository = githubAnalysisResultRepository;
    }

    /**
     * 1. 메서드 설명: 선택된 GitHub repository 정보를 저장하는 API.
     * 2. 로직:
     *    - SecurityContext에서 현재 인증된 사용자의 username을 조회한다.
     *    - username을 이용해 User 엔티티를 검색하여 사용자 정보를 가져온다.
     *    - 조회된 User 엔티티의 id를 사용해 GithubRepository 엔티티를 조회한다.
     *    - 전달받은 repository ID 배열을 Set으로 변환한 후, GithubRepository에 저장된 repository 목록 중 선택된 항목을 필터링한다.
     *    - 필터링된 repository 리스트와 userId를 바탕으로 SelectedRepository 엔티티를 생성 및 저장한다.
     * 3. param: selectedGithubRepositories - 사용자가 선택한 repository의 ID 배열.
     * 4. return: 성공 시 "레포지토리 선택 저장 요청 처리 완료" 메시지를 포함한 MessageOnlyResponse 객체.
     */
    public MessageOnlyResponse saveSelectedGithubRepository(int[] selectedGithubRepositories) {
        String username = getUserName();

        User user = userRepository.findByGithubName(username)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        int userId = user.getId();

        GithubRepository githubRepository = githubRepoRepository.findByUserId(userId)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

        Set<Integer> selectedIds = Arrays.stream(selectedGithubRepositories)
                .boxed()
                .collect(Collectors.toSet());

        List<Repository> selectedRepositories = githubRepository.getRepositories().stream()
                .filter(repo -> selectedIds.contains(repo.getRepoId()))
                .collect(Collectors.toList());

        SelectedRepository selectedRepository = SelectedRepository.builder()
                .userId(userId)
                .repositories(selectedRepositories)
                .build();

        selectedRepoRepository.save(selectedRepository);

        return MessageOnlyResponse.builder()
                .message("레포지토리 선택 저장 요청 처리 완료")
                .build();
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
    public void analysisAllRepository(int userId) {
        GithubRepository githubRepository = githubRepoRepository.findByUserId(userId)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));

        List<Repository> repositories = githubRepository.getRepositories();

        List<String> repositoryPathUrls = repositories.stream()
                .map(repository -> {
                    String repoFullName = repository.getFullName();

                    return "https://github.com/" + repoFullName + ".git";
                })
                .toList();

        for (String repositoryPathUrl : repositoryPathUrls) {
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
                log.info("Starting sonar scanner for project : {}, project Key : {}", repositoryPathUrl, projectKey);

                Process process = processBuilder.start();
                int exitCode = process.exitValue();
                if (exitCode != 0) {
                    log.error("sonar-scanner failed for project {} with exit code {}", repositoryPathUrl, exitCode);
                }

                GithubAnalysisResult result = pollAnalysisResult(projectKey);
                githubAnalysisResultRepository.save(result);
                log.info("Analysis result saved for project: {}", repositoryPathUrl);
            } catch (Exception e) {
                log.error("Exception while analyzing repository: {}", repositoryPathUrl, e);
                throw new SonarAnalysisException("SonarQube analysis failed : " + e.getMessage());
            }
        }
    }
    private GithubAnalysisResult pollAnalysisResult(String projectKey) throws InterruptedException {
        Thread.sleep(30000);
        return GithubAnalysisResult.builder().build();
    }

    private File cloneRepository(String repoUrl) {
        String projectKey = extractProjectKey(repoUrl);
        File repoDir = new File("/tmp/repositories/" + projectKey);
        if (!repoDir.exists()) {
            log.info("Cloning repository {} into {}", repoUrl, repoDir.getAbsolutePath());
        }
        return repoDir;
    }

    private String extractProjectKey(String repoUrl) {
        String[] parts = repoUrl.split("/");
        String org = parts[parts.length - 2];
        String project = parts[parts.length - 1].replace(".git", "");
        return org + "_" + project;
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

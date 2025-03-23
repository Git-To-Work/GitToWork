package com.gittowork.global.service;

import com.gittowork.domain.github.entity.*;
import com.gittowork.domain.github.repository.*;
import com.gittowork.global.exception.GithubRepositoryNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class GithubRestApiService {

    private final RestTemplate restTemplate;
    private final GithubRepoRepository githubRepoRepository;
    private final GithubCommitRepository githubCommitRepository;
    private final GithubLanguageRepository githubLanguageRepository;
    private final GithubIssueRepository githubIssueRepository;
    private final GithubPullRequestRepository githubPullRequestRepository;
    private final GithubCodeRepository githubCodeRepository;
    private final GithubEventRepository githubEventRepository;

    @Value("${github.client.id}")
    private String clientId;

    @Value("${github.client.secret}")
    private String clientSecret;

    @Value("${github.redirect.uri}")
    private String redirectUri;

    @Autowired
    public GithubRestApiService(RestTemplate restTemplate,
                                GithubRepoRepository githubRepoRepository,
                                GithubCommitRepository githubCommitRepository,
                                GithubLanguageRepository githubLanguageRepository,
                                GithubIssueRepository githubIssueRepository,
                                GithubPullRequestRepository githubPullRequestRepository,
                                GithubCodeRepository githubCodeRepository, GithubEventRepository githubEventRepository) {
        this.restTemplate = restTemplate;
        this.githubRepoRepository = githubRepoRepository;
        this.githubCommitRepository = githubCommitRepository;
        this.githubLanguageRepository = githubLanguageRepository;
        this.githubIssueRepository = githubIssueRepository;
        this.githubPullRequestRepository = githubPullRequestRepository;
        this.githubCodeRepository = githubCodeRepository;
        this.githubEventRepository = githubEventRepository;
    }

    // ============================================================
    // 1. 인증 및 사용자 정보 관련 메서드
    // ============================================================

    /**
     * 1. 메서드 설명: GitHub OAuth 인증 과정에서 전달받은 code를 사용하여 access token 정보를 가져오는 API.
     * 2. 로직:
     *    - 요청 헤더에 JSON 형식의 응답을 수락하도록 설정하고, 요청 본문에 client_id, client_secret, redirect_uri, code를 추가한다.
     *    - GitHub OAuth access token URL에 POST 요청을 보내 응답 상태 코드가 2xx가 아니면 예외를 발생시키고,
     *      2xx인 경우 응답 본문이 null이면 빈 Map으로 처리한 후 access token 정보를 반환한다.
     * 3. param: code - GitHub OAuth 인증 코드.
     * 4. return: GitHub access token 정보를 포함한 Map 객체.
     */
    public Map<String, Object> getAccessToken(String code) {
        HttpHeaders headers = new HttpHeaders();
        headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));
        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("client_id", clientId);
        body.add("client_secret", clientSecret);
        body.add("redirect_uri", redirectUri);
        body.add("code", code);
        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(body, headers);
        String accessTokenUrl = "https://github.com/login/oauth/access_token";
        ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                accessTokenUrl,
                HttpMethod.POST,
                request,
                new ParameterizedTypeReference<Map<String, Object>>() {}
        );
        if (!response.getStatusCode().is2xxSuccessful()) {
            throw new GithubRepositoryNotFoundException("Failed to get access token - HTTP " + response.getStatusCode());
        }
        Map<String, Object> bodyResponse = response.getBody();
        return bodyResponse == null ? Collections.emptyMap() : bodyResponse;
    }

    /**
     * 1. 메서드 설명: GitHub API를 호출하여 access token 기반으로 사용자 정보를 조회하는 API.
     * 2. 로직:
     *    - 요청 헤더에 bearer 토큰 방식으로 access token을 설정하고, JSON 형식의 응답을 수락하도록 설정한다.
     *    - GitHub 사용자 정보 API에 GET 요청을 보내 응답 상태가 2xx가 아니면 예외를 발생시키며,
     *      2xx인 경우 응답 본문이 null이면 빈 Map으로 처리한 후 사용자 정보를 반환한다.
     * 3. param: accessToken - GitHub API 접근에 사용되는 access token.
     * 4. return: GitHub 사용자 정보를 포함한 Map 객체.
     */
    public Map<String, Object> getUserInfo(String accessToken) {
        HttpEntity<String> request = new HttpEntity<>(createHeaders(accessToken, MediaType.APPLICATION_JSON));
        ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                "https://api.github.com/user",
                HttpMethod.GET,
                request,
                new ParameterizedTypeReference<Map<String, Object>>() {}
        );
        if (!response.getStatusCode().is2xxSuccessful()) {
            throw new GithubRepositoryNotFoundException("Failed to get user info - HTTP " + response.getStatusCode());
        }
        Map<String, Object> bodyResponse = response.getBody();
        return bodyResponse == null ? Collections.emptyMap() : bodyResponse;
    }

    // ============================================================
    // 2. Repository 관련 메서드
    // ============================================================

    /**
     * 1. 메서드 설명: GitHub API를 호출하여 사용자의 repository 정보를 조회하고,
     *    이를 데이터베이스에 저장하는 메서드.
     * 2. 로직:
     *    - 요청 헤더에 bearer 토큰 방식의 access token을 설정하고, JSON 응답을 수락한다.
     *    - GitHub 사용자 repository API에 GET 요청을 보내 응답 상태가 2xx가 아니면 예외를 발생시키며,
     *      응답 본문이 null이면 빈 리스트로 처리한다.
     *    - 응답 데이터를 Repository 객체로 변환 후 GithubRepository 엔티티에 담아 저장한다.
     * 3. param:
     *      accessToken - GitHub API 접근에 사용되는 access token.
     *      githubName  - GitHub 사용자 이름.
     *      userId      - 현재 애플리케이션 사용자 ID.
     * 4. return: 없음.
     */
    public void saveUserGithubRepository(String accessToken, String githubName, int userId) {
        HttpEntity<String> request = new HttpEntity<>(createHeaders(accessToken, MediaType.APPLICATION_JSON));
        ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                "https://api.github.com/users/{githubName}/repos",
                HttpMethod.GET,
                request,
                new ParameterizedTypeReference<List<Map<String, Object>>>() {},
                githubName
        );
        if (!response.getStatusCode().is2xxSuccessful()) {
            throw new GithubRepositoryNotFoundException("Failed to fetch repositories - HTTP " + response.getStatusCode());
        }
        List<Map<String, Object>> responseBody = response.getBody();
        List<Repository> repositories = (responseBody == null ? Collections.emptyList() : responseBody)
                .stream()
                .map(obj -> {
                    Map<String, Object> map = (Map<String, Object>) obj;
                    return Repository.builder()
                            .repoId((Integer) map.get("id"))
                            .repoName(map.get("name").toString())
                            .fullName(map.get("full_name").toString())
                            .language(map.get("language") != null ? map.get("language").toString() : null)
                            .stargazersCount((Integer) map.get("stargazers_count"))
                            .forksCount((Integer) map.get("forks_count"))
                            .createdAt(LocalDateTime.parse(map.get("created_at").toString()))
                            .updatedAt(LocalDateTime.parse(map.get("updated_at").toString()))
                            .pushedAt(LocalDateTime.parse(map.get("pushed_at").toString()))
                            .description(map.get("description") != null ? map.get("description").toString() : "")
                            .build();
                })
                .collect(Collectors.toList());
        GithubRepository githubRepository = GithubRepository.builder()
                .userId(userId)
                .repositories(repositories)
                .build();
        githubRepoRepository.save(githubRepository);
    }

    // ============================================================
    // 3. Commit 관련 메서드
    // ============================================================

    /**
     * 1. 메서드 설명: GitHub API를 호출하여 사용자의 commit 정보를 조회하고,
     *    각 commit의 파일 변경 내역 중 코드 파일(주 언어 파일)만 필터링하여 데이터베이스에 저장하는 메서드.
     * 2. 로직:
     *    - 일반 조회용과 상세 조회용 HTTP 헤더를 생성한다.
     *    - userId에 해당하는 repository 목록을 조회한다.
     *    - 각 repository마다 commit 목록을 GET 요청으로 조회하며, 상태가 2xx가 아니면 예외를 발생시키고,
     *      응답 본문이 null이면 빈 리스트로 처리한다.
     *    - 각 commit마다 parseCommit()을 호출하여 Commit 객체로 변환한다.
     *    - 변환된 Commit 리스트를 포함하는 GithubCommit 엔티티를 생성 후 배치 저장한다.
     * 3. param:
     *      accessToken - GitHub API 접근에 사용되는 access token.
     *      githubName  - GitHub 사용자 이름.
     *      userId      - 현재 애플리케이션 사용자 ID.
     * 4. return: 없음.
     */
    public void saveUserGithubCommits(String accessToken, String githubName, int userId) {
        HttpEntity<String> request = new HttpEntity<>(createHeaders(accessToken, MediaType.APPLICATION_JSON));
        HttpEntity<String> detailRequest = new HttpEntity<>(createHeaders(accessToken, MediaType.valueOf("application/vnd.github.v3+json")));
        List<Repository> repositories = githubRepoRepository.findByUserId(userId)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"))
                .getRepositories();
        List<GithubCommit> githubCommits = repositories.stream().map(repository -> {
            String repositoryName = repository.getRepoName();
            int repoId = repository.getRepoId();
            ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                    "https://api.github.com/repos/{githubName}/{repositoryName}/commits",
                    HttpMethod.GET,
                    request,
                    new ParameterizedTypeReference<List<Map<String, Object>>>() {},
                    githubName,
                    repositoryName
            );
            if (!response.getStatusCode().is2xxSuccessful()) {
                throw new GithubRepositoryNotFoundException("Failed to fetch commits for repository: " + repositoryName + " - HTTP " + response.getStatusCode());
            }
            List<Map<String, Object>> responseBody = response.getBody();
            List<Commit> commits = (responseBody == null ? Collections.<Map<String, Object>>emptyList() : responseBody).stream()
                    .map((Map<String, Object> commitMap) -> parseCommit(commitMap, githubName, repositoryName, detailRequest))
                    .collect(Collectors.toList());
            return GithubCommit.builder()
                    .userId(userId)
                    .repoId(repoId)
                    .commits(commits)
                    .build();
        }).collect(Collectors.toList());
        githubCommitRepository.saveAll(githubCommits);
    }

    /**
     * 1. 메서드 설명: API 응답 데이터에서 commit 정보를 파싱하여 Commit 객체를 생성하는 메서드.
     * 2. 로직:
     *    - commitMap으로부터 commit 정보, SHA, 메시지, 작성자, 작성 날짜를 추출한다.
     *    - fetchFilesChanged()를 호출하여 해당 commit의 파일 변경 내역(코드 파일만)을 조회한다.
     *    - 빌더 패턴을 활용하여 Commit 객체를 생성한다.
     * 3. param:
     *      commitMap      - GitHub commit API 응답 데이터의 Map.
     *      githubName     - GitHub 사용자 이름.
     *      repositoryName - repository 이름.
     *      detailRequest  - 상세 commit API 호출을 위한 HttpEntity.
     * 4. return: 파싱된 정보를 기반으로 생성된 Commit 객체.
     */
    private Commit parseCommit(Map<String, Object> commitMap, String githubName, String repositoryName, HttpEntity<String> detailRequest) {
        @SuppressWarnings("unchecked")
        Map<String, Object> commitInfo = (Map<String, Object>) commitMap.get("commit");
        String sha = (String) commitMap.get("sha");
        String message = (String) commitInfo.get("message");
        @SuppressWarnings("unchecked")
        Map<String, Object> authorInfo = (Map<String, Object>) commitInfo.get("author");
        String dateString = (String) authorInfo.get("date");
        LocalDateTime commitDate = OffsetDateTime.parse(dateString).toLocalDateTime();
        Map<String, String> authorMap = Map.of(
                "name", (String) authorInfo.get("name"),
                "email", (String) authorInfo.get("email")
        );
        List<String> filesChanged = fetchFilesChanged(githubName, repositoryName, sha, detailRequest);
        return Commit.builder()
                .commitSha(sha)
                .commitMessage(message)
                .commitDate(commitDate)
                .author(authorMap)
                .filesChanged(filesChanged)
                .build();
    }

    /**
     * 1. 메서드 설명: GitHub 상세 commit API를 호출하여 commit의 파일 변경 내역에서,
     *    코드 파일(주 언어 파일)에 해당하는 파일의 filename을 추출하여 반환하는 헬퍼 메서드.
     * 2. 로직:
     *    - commit SHA를 이용해 상세 commit API를 호출하고, 응답 상태가 2xx가 아니면 예외를 발생시킨다.
     *    - 응답 데이터의 "files" 항목을 순회하면서, isCodeFile()을 통해 코드 파일로 판단되면 filename을 추출한다.
     *    - 코드 파일이 아닌 경우는 제외하고, 해당 filename들의 List를 반환한다.
     * 3. param:
     *      githubName     - GitHub 사용자 이름.
     *      repositoryName - repository 이름.
     *      sha            - commit SHA.
     *      detailRequest  - 상세 commit API 호출을 위한 HttpEntity.
     * 4. return: 코드 파일에 해당하는 filename들을 포함한 List<String> 객체.
     */
    @SuppressWarnings("unchecked")
    private List<String> fetchFilesChanged(String githubName, String repositoryName, String sha, HttpEntity<String> detailRequest) {
        ResponseEntity<Map<String, Object>> detailResponse = restTemplate.exchange(
                "https://api.github.com/repos/{githubName}/{repositoryName}/commits/{sha}",
                HttpMethod.GET,
                detailRequest,
                new ParameterizedTypeReference<Map<String, Object>>() {},
                githubName,
                repositoryName,
                sha
        );
        if (!detailResponse.getStatusCode().is2xxSuccessful()) {
            throw new GithubRepositoryNotFoundException("Failed to fetch commit details for sha: " + sha + " - HTTP " + detailResponse.getStatusCode());
        }
        Map<String, Object> detailBody = detailResponse.getBody();
        if (detailBody == null) {
            return Collections.emptyList();
        }
        List<Map<String, Object>> filesList = (List<Map<String, Object>>) detailBody.get("files");
        if (filesList == null) {
            return Collections.emptyList();
        }
        return filesList.stream()
                .filter(fileMap -> {
                    String fullFilename = (String) fileMap.get("filename");
                    return isCodeFile(fullFilename);
                })
                .map(fileMap -> (String) fileMap.get("filename"))
                .collect(Collectors.toList());
    }

    /**
     * 1. 메서드 설명: 파일 이름을 기반으로 해당 파일이 코드 파일(주 언어 파일)인지 판별한다.
     * 2. 로직:
     *    - 허용된 확장자 목록에 해당하면 코드 파일로 판단한다.
     * 3. param:
     *      filename - 파일의 전체 경로 또는 이름.
     * 4. return: 코드 파일이면 true, 그렇지 않으면 false.
     */
    private boolean isCodeFile(String filename) {
        if (filename == null) return false;
        String lower = filename.toLowerCase();
        return lower.endsWith(".java") ||
                lower.endsWith(".py") ||
                lower.endsWith(".js") ||
                lower.endsWith(".ts") ||
                lower.endsWith(".html") ||
                lower.endsWith(".css") ||
                lower.endsWith(".cpp") ||
                lower.endsWith(".c") ||
                lower.endsWith(".cs") ||
                lower.endsWith(".rb") ||
                lower.endsWith(".go") ||
                lower.endsWith(".kt");
    }

    // ============================================================
    // 4. Language 관련 메서드
    // ============================================================

    /**
     * 1. 메서드 설명: GitHub API를 호출하여 사용자의 각 repository에 대한 언어 정보를 조회하고,
     *    이를 GithubLanguage 엔티티로 변환하여 데이터베이스에 저장하는 메서드.
     * 2. 로직:
     *    - accessToken과 githubName을 이용해 HTTP 헤더를 생성한다.
     *    - userId에 해당하는 repository 목록을 조회하고, 각 repository마다 /languages 엔드포인트를 호출하여 언어 정보를 조회한다.
     *      응답 상태가 2xx가 아니면 예외를 발생시키며, 응답 본문이 null이면 빈 Map으로 처리한다.
     *    - 조회된 언어 정보를 기반으로 GithubLanguage 객체를 생성하여 저장한다.
     * 3. param:
     *      accessToken - GitHub API 접근에 사용되는 access token.
     *      githubName  - GitHub 사용자 이름.
     *      userId      - 현재 애플리케이션 사용자 ID.
     * 4. return: 없음.
     */
    public void saveUserRepositoryLanguage(String accessToken, String githubName, int userId) {
        HttpEntity<String> request = new HttpEntity<>(createHeaders(accessToken, MediaType.APPLICATION_JSON));
        List<Repository> repositories = githubRepoRepository.findByUserId(userId)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"))
                .getRepositories();
        List<GithubLanguage> languages = repositories.stream().map(repository -> {
            String repositoryName = repository.getRepoName();
            int repoId = repository.getRepoId();
            ResponseEntity<Map<String, Long>> response = restTemplate.exchange(
                    "https://api.github.com/repos/{githubName}/{repositoryName}/languages",
                    HttpMethod.GET,
                    request,
                    new ParameterizedTypeReference<Map<String, Long>>() {},
                    githubName,
                    repositoryName
            );
            if (!response.getStatusCode().is2xxSuccessful()) {
                throw new GithubRepositoryNotFoundException("Failed to fetch languages for repository: " + repositoryName + " - HTTP " + response.getStatusCode());
            }
            Map<String, Long> languageMap = response.getBody();
            languageMap = languageMap == null ? Collections.emptyMap() : languageMap;
            return GithubLanguage.builder()
                    .userId(userId)
                    .repoId(repoId)
                    .languages(languageMap)
                    .build();
        }).collect(Collectors.toList());
        githubLanguageRepository.saveAll(languages);
    }

    // ============================================================
    // 5. Issue 관련 메서드
    // ============================================================

    /**
     * 1. 메서드 설명: GitHub API를 호출하여 chanhoan/chanhoan_Github repository의 모든 이슈 정보를 조회하고,
     *    이를 GithubIssue Document로 변환하여 데이터베이스에 저장하는 메서드.
     * 2. 로직:
     *    - accessToken을 이용해 HTTP 헤더를 생성하고, /issues?state=all 엔드포인트에 GET 요청을 보낸다.
     *      응답 상태가 2xx가 아니면 예외를 발생시키며, 응답 본문이 null이면 빈 리스트로 처리한다.
     *    - 응답받은 이슈 리스트를 순회하며 parseIssue()로 변환한 후 배치 저장한다.
     * 3. param:
     *      accessToken - GitHub API 접근에 사용되는 access token.
     * 4. return: 없음.
     */
    public void saveGithubIssues(String accessToken) {
        HttpEntity<String> request = new HttpEntity<>(createHeaders(accessToken, MediaType.valueOf("application/vnd.github.v3+json")));
        String url = "https://api.github.com/repos/chanhoan/chanhoan_Github/issues?state=all";
        ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                request,
                new ParameterizedTypeReference<List<Map<String, Object>>>() {}
        );
        if (!response.getStatusCode().is2xxSuccessful()) {
            throw new GithubRepositoryNotFoundException("Failed to fetch issues - HTTP " + response.getStatusCode());
        }
        List<Map<String, Object>> issuesData = response.getBody();
        issuesData = issuesData == null ? Collections.emptyList() : issuesData;
        List<GithubIssue> issues = issuesData.stream()
                .map(this::parseIssue)
                .collect(Collectors.toList());
        githubIssueRepository.saveAll(issues);
    }

    /**
     * 1. 메서드 설명: API 응답 데이터의 개별 이슈 정보를 파싱하여 GithubIssue 객체로 변환하는 헬퍼 메서드.
     * 2. 로직:
     *    - 기본 필드(repo_id, issue_id, url, comments_url, title, body, comments)를 추출하고,
     *      중첩 객체(user, labels, assignee, assignees)는 각각 파싱한다.
     * 3. param:
     *      issueMap - GitHub 이슈 API 응답 데이터의 Map.
     * 4. return: 파싱된 정보를 기반으로 생성된 GithubIssue 객체.
     */
    private GithubIssue parseIssue(Map<String, Object> issueMap) {
        int repoId = ((Number) issueMap.get("repo_id")).intValue();
        long issueId = ((Number) issueMap.get("issue_id")).longValue();
        String url = (String) issueMap.get("url");
        String commentsUrl = (String) issueMap.get("comments_url");
        String title = (String) issueMap.get("title");
        String body = (String) issueMap.get("body");
        int comments = ((Number) issueMap.get("comments")).intValue();
        @SuppressWarnings("unchecked")
        Map<String, Object> userMap = (Map<String, Object>) issueMap.get("user");
        GithubIssueUser user = parseIssueUser(userMap);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> labelsList = (List<Map<String, Object>>) issueMap.get("labels");
        List<GithubIssueLabel> labels = Optional.ofNullable(labelsList)
                .orElse(Collections.emptyList())
                .stream()
                .map(this::parseLabel)
                .collect(Collectors.toList());
        GithubIssueUser assignee = null;
        if (issueMap.get("assignee") != null) {
            @SuppressWarnings("unchecked")
            Map<String, Object> assigneeMap = (Map<String, Object>) issueMap.get("assignee");
            assignee = parseIssueUser(assigneeMap);
        }
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> assigneesList = (List<Map<String, Object>>) issueMap.get("assignees");
        List<GithubIssueUser> assignees = Optional.ofNullable(assigneesList)
                .orElse(Collections.emptyList())
                .stream()
                .map(this::parseIssueUser)
                .collect(Collectors.toList());
        return GithubIssue.builder()
                .repoId(repoId)
                .issueId(issueId)
                .url(url)
                .commentsUrl(commentsUrl)
                .title(title)
                .body(body)
                .user(user)
                .labels(labels)
                .assignee(assignee)
                .assignees(assignees)
                .comments(comments)
                .build();
    }

    /**
     * 1. 메서드 설명: GitHub 이슈의 사용자 정보를 파싱하여 GithubIssueUser 객체로 변환하는 헬퍼 메서드.
     * 2. 로직:
     *    - userMap으로부터 login과 id 값을 추출한다.
     * 3. param:
     *      userMap - GitHub 이슈 API 응답의 user 데이터 Map.
     * 4. return: 파싱된 정보를 기반으로 생성된 GithubIssueUser 객체.
     */
    private GithubIssueUser parseIssueUser(Map<String, Object> userMap) {
        String login = (String) userMap.get("login");
        int id = ((Number) userMap.get("id")).intValue();
        return GithubIssueUser.builder()
                .login(login)
                .id(id)
                .build();
    }

    /**
     * 1. 메서드 설명: GitHub 이슈의 레이블 정보를 파싱하여 GithubIssueLabel 객체로 변환하는 헬퍼 메서드.
     * 2. 로직:
     *    - labelMap에서 id, name, color, description 값을 추출한다.
     * 3. param:
     *      labelMap - GitHub 이슈 API 응답의 레이블 데이터 Map.
     * 4. return: 파싱된 정보를 기반으로 생성된 GithubIssueLabel 객체.
     */
    private GithubIssueLabel parseLabel(Map<String, Object> labelMap) {
        int id = ((Number) labelMap.get("id")).intValue();
        String name = (String) labelMap.get("name");
        String color = (String) labelMap.get("color");
        String description = (String) labelMap.get("description");
        return GithubIssueLabel.builder()
                .id(id)
                .name(name)
                .color(color)
                .description(description)
                .build();
    }

    // ============================================================
    // 6. Pull Request 관련 메서드
    // ============================================================

    /**
     * 1. 메서드 설명: GitHub API를 호출하여 kobenlys/K6Weaver repository의 모든 Pull Request 정보를 조회하고,
     *    이를 GithubPullRequest Document로 변환하여 데이터베이스에 저장하는 메서드.
     * 2. 로직:
     *    - accessToken을 이용해 HTTP 헤더를 생성하고, /pulls?state=all 엔드포인트에 GET 요청을 보낸다.
     *      응답 상태가 2xx가 아니면 예외를 발생시키며, 응답 본문이 null이면 빈 리스트로 처리한다.
     *    - 응답받은 PR 리스트를 순회하며 parsePullRequest()를 통해 GithubPullRequest 객체로 변환한 후 배치 저장한다.
     * 3. param:
     *      accessToken - GitHub API 접근에 사용되는 access token.
     * 4. return: 없음.
     */
    public void saveGithubPullRequests(String accessToken) {
        HttpEntity<String> request = new HttpEntity<>(createHeaders(accessToken, MediaType.valueOf("application/vnd.github.v3+json")));
        String url = "https://api.github.com/repos/kobenlys/K6Weaver/pulls?state=all";
        ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                request,
                new ParameterizedTypeReference<List<Map<String, Object>>>() {}
        );
        if (!response.getStatusCode().is2xxSuccessful()) {
            throw new GithubRepositoryNotFoundException("Failed to fetch pull requests - HTTP " + response.getStatusCode());
        }
        List<Map<String, Object>> prList = response.getBody();
        prList = prList == null ? Collections.emptyList() : prList;
        List<GithubPullRequest> pullRequests = prList.stream()
                .map(this::parsePullRequest)
                .collect(Collectors.toList());
        githubPullRequestRepository.saveAll(pullRequests);
    }

    /**
     * 1. 메서드 설명: API 응답 데이터의 개별 Pull Request 정보를 파싱하여 GithubPullRequest 객체로 변환하는 헬퍼 메서드.
     * 2. 로직:
     *    - base.repo.full_name 값을 통해 저장소 식별자(repoId)를 추출하고,
     *      "number", URL, title, body 등 기본 필드를 추출하며, comments, review_comments, commits 값은 없으면 0으로 기본 설정한다.
     *    - user, head, base 객체는 각각의 헬퍼 메서드(parsePRUser, parsePRBranch)를 사용하여 파싱한다.
     * 3. param:
     *      prMap - GitHub Pull Request API 응답 데이터의 Map.
     * 4. return: 파싱된 정보를 기반으로 생성된 GithubPullRequest 객체.
     */
    private GithubPullRequest parsePullRequest(Map<String, Object> prMap) {
        @SuppressWarnings("unchecked")
        Map<String, Object> baseMap = (Map<String, Object>) prMap.get("base");
        @SuppressWarnings("unchecked")
        Map<String, Object> baseRepo = (Map<String, Object>) baseMap.get("repo");
        String repoId = (String) baseRepo.get("full_name");
        int prId = ((Number) prMap.get("number")).intValue();
        String url = (String) prMap.get("url");
        String htmlUrl = (String) prMap.get("html_url");
        String diffUrl = (String) prMap.get("diff_url");
        String patchUrl = (String) prMap.get("patch_url");
        String title = (String) prMap.get("title");
        String body = (String) prMap.get("body");
        int commentsCount = prMap.get("comments") != null ? ((Number) prMap.get("comments")).intValue() : 0;
        int reviewCommentsCount = prMap.get("review_comments") != null ? ((Number) prMap.get("review_comments")).intValue() : 0;
        int commitsCount = prMap.get("commits") != null ? ((Number) prMap.get("commits")).intValue() : 0;
        @SuppressWarnings("unchecked")
        Map<String, Object> userMap = (Map<String, Object>) prMap.get("user");
        GithubPullRequestUser user = parsePRUser(userMap);
        @SuppressWarnings("unchecked")
        Map<String, Object> headMap = (Map<String, Object>) prMap.get("head");
        GithubPullRequestBranch head = parsePRBranch(headMap);
        GithubPullRequestBranch base = parsePRBranch(baseMap);
        return GithubPullRequest.builder()
                .repoId(repoId)
                .prId(prId)
                .url(url)
                .htmlUrl(htmlUrl)
                .diffUrl(diffUrl)
                .patchUrl(patchUrl)
                .title(title)
                .body(body)
                .commentsCount(commentsCount)
                .reviewCommentsCount(reviewCommentsCount)
                .commitsCount(commitsCount)
                .user(user)
                .head(head)
                .base(base)
                .build();
    }

    /**
     * 1. 메서드 설명: GitHub Pull Request의 사용자 정보를 파싱하여 GithubPullRequestUser 객체로 변환하는 헬퍼 메서드.
     * 2. 로직:
     *    - userMap으로부터 login과 id 값을 추출하며, id는 int 타입으로 처리한다.
     * 3. param:
     *      userMap - GitHub Pull Request API 응답의 user 데이터 Map.
     * 4. return: 파싱된 정보를 기반으로 생성된 GithubPullRequestUser 객체.
     */
    private GithubPullRequestUser parsePRUser(Map<String, Object> userMap) {
        String login = (String) userMap.get("login");
        int id = ((Number) userMap.get("id")).intValue();
        return GithubPullRequestUser.builder()
                .login(login)
                .id(id)
                .build();
    }

    /**
     * 1. 메서드 설명: Pull Request 응답 데이터의 브랜치(head/base) 정보를 파싱하여 GithubPullRequestBranch 객체로 변환하는 헬퍼 메서드.
     * 2. 로직:
     *    - branchMap으로부터 label, ref, sha 값을 추출하고, 내부의 user 객체는 parsePRUser()를 통해 파싱한다.
     * 3. param:
     *      branchMap - GitHub Pull Request API 응답의 head/base 데이터 Map.
     * 4. return: 파싱된 정보를 기반으로 생성된 GithubPullRequestBranch 객체.
     */
    private GithubPullRequestBranch parsePRBranch(Map<String, Object> branchMap) {
        String label = (String) branchMap.get("label");
        String ref = (String) branchMap.get("ref");
        String sha = (String) branchMap.get("sha");
        GithubPullRequestUser user = null;
        if (branchMap.get("user") != null) {
            @SuppressWarnings("unchecked")
            Map<String, Object> userMap = (Map<String, Object>) branchMap.get("user");
            user = parsePRUser(userMap);
        }
        return GithubPullRequestBranch.builder()
                .label(label)
                .ref(ref)
                .sha(sha)
                .user(user)
                .build();
    }

    // ============================================================
    // 7. Code 관련 메서드
    // ============================================================

    /**
     * 1. 메서드 설명: 사용자 GitHub repository의 commit 정보를 조회하여, 각 commit의 파일 내용을 상세 API를 통해 가져와서
     *    GithubCode 엔티티에 저장하는 메서드.
     * 2. 로직:
     *    - accessToken과 userName을 사용하여 HTTP 헤더를 생성한다.
     *    - userId로 해당 사용자의 repository 목록을 조회하고, 각 repository마다 commit 목록을 조회한다.
     *    - 각 commit에서 변경된 파일 목록(filesChanged)을 순회하며 파일의 상세 내용을 GitHub API를 통해 조회하고,
     *      HTTP 상태가 2xx가 아니면 예외를 발생시키며, 응답 본문이 null이면 해당 파일은 건너뛴다.
     *    - 조회된 파일 내용을 포함하여 GithubCode 객체를 생성한 후 배치 저장한다.
     * 3. param:
     *      accessToken - GitHub API 호출에 사용되는 access token.
     *      userName    - GitHub 사용자 이름.
     *      userId      - 로컬 사용자 식별자.
     * 4. return: 없음.
     */
    public void saveGithubCode(String accessToken, String userName, int userId) {
        HttpEntity<String> request = new HttpEntity<>(createHeaders(accessToken, MediaType.valueOf("application/vnd.github.v3+json")));
        List<Repository> repositories = githubRepoRepository.findByUserId(userId)
                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"))
                .getRepositories();
        List<GithubCode> githubCodes = repositories.stream()
                .flatMap(repository -> {
                    String repoName = repository.getRepoName();
                    int repoId = repository.getRepoId();
                    GithubCommit githubCommit = githubCommitRepository.findByRepoId(repoId)
                            .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"));
                    return githubCommit.getCommits().stream()
                            .flatMap(commit -> {
                                String commitSha = commit.getCommitSha();
                                LocalDateTime commitDate = commit.getCommitDate();
                                return commit.getFilesChanged().stream()
                                        .map(filePath -> {
                                            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                                                    "https://api.github.com/repos/{githubName}/{repositoryName}/contents/{fileName}?ref={commitSha}",
                                                    HttpMethod.GET,
                                                    request,
                                                    new ParameterizedTypeReference<Map<String, Object>>() {},
                                                    userName,
                                                    repoName,
                                                    filePath,
                                                    commitSha
                                            );
                                            if (!response.getStatusCode().is2xxSuccessful()) {
                                                throw new GithubRepositoryNotFoundException("Failed to fetch code for file: " + filePath + " - HTTP " + response.getStatusCode());
                                            }
                                            Map<String, Object> commitContents = response.getBody();
                                            if (commitContents == null || commitContents.get("contents") == null) {
                                                throw new GithubRepositoryNotFoundException("No content found for file: " + filePath);
                                            }
                                            return GithubCode.builder()
                                                    .userId(userId)
                                                    .repoId(repoId)
                                                    .commitSha(commitSha)
                                                    .commitDate(commitDate)
                                                    .fileName(filePath)
                                                    .codeContent((String) commitContents.get("content"))
                                                    .build();
                                        });
                            });
                })
                .collect(Collectors.toList());
        githubCodeRepository.saveAll(githubCodes);
    }

    // ============================================================
    // 8. Event 관련 메서드
    // ============================================================

    /**
     * 1. 메서드 설명: GitHub API를 호출하여 사용자의 이벤트 정보를 조회하고,
     *    DB에 저장된 최신 이벤트와 비교하여 새로운 이벤트가 추가되었는지 여부를 판단하는 메서드.
     * 2. 로직:
     *    - accessToken과 userName을 사용하여 HTTP 헤더를 생성한 후, "https://api.github.com/users/{userName}/events" 엔드포인트에 GET 요청을 보낸다.
     *    - 응답 상태가 2xx가 아니면 예외를 발생시키며, 응답 본문이 null이면 빈 리스트로 처리한다.
     *    - (A) API 응답 이벤트가 없을 경우:
     *         - DB에서 해당 사용자의 최신 이벤트를 조회한다.
     *         - 최신 이벤트의 생성일이 현재 시간 기준 90일 이전이면 true, 90일 이내이면 false를 반환한다.
     *         - DB에 이벤트가 하나도 없으면 새로운 이벤트가 있다고 판단하여 true를 반환한다.
     *    - (B) API 응답 이벤트가 있는 경우:
     *         - 응답 이벤트 목록 중 event type이 "PushEvent", "IssuesEvent", "PullRequestEvent" 중 하나라도 존재하면 true, 그렇지 않으면 false를 반환한다.
     * 3. param:
     *      accessToken - GitHub API 접근에 사용되는 access token.
     *      userName    - GitHub 사용자 이름.
     *      userId      - 현재 애플리케이션 사용자 ID.
     * 4. return: 새로운 이벤트가 존재하면 true, 그렇지 않으면 false.
     */
    public boolean checkNewGithubEvents(String accessToken, String userName, int userId) {
        HttpEntity<String> request = new HttpEntity<>(createHeaders(accessToken, MediaType.APPLICATION_JSON));
        ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                "https://api.github.com/users/{userName}/events",
                HttpMethod.GET,
                request,
                new ParameterizedTypeReference<List<Map<String, Object>>>() {},
                userName
        );
        if (!response.getStatusCode().is2xxSuccessful()) {
            throw new GithubRepositoryNotFoundException("Failed to fetch events - HTTP " + response.getStatusCode());
        }
        List<Map<String, Object>> apiEvents = response.getBody();
        apiEvents = (apiEvents == null ? Collections.emptyList() : apiEvents);

        // (A) API 응답 이벤트가 없을 경우 : DB의 최신 이벤트와 날짜 비교
        if (apiEvents.isEmpty()) {
            Optional<GithubEvent> latestEventOpt = githubEventRepository.findTopByUserIdOrderByEventsCreatedAtDesc(userId);
            if (latestEventOpt.isPresent()) {
                LocalDateTime lastEventTime = latestEventOpt.get().getEvents().getCreatedAt();
                return lastEventTime.isBefore(LocalDateTime.now().minusDays(90));
            } else {
                return true;
            }
        }

        // (B) API 응답 이벤트가 있을 경우 : 이벤트 타입이 Push, Issues, PullRequest 인지 확인
        Set<String> allowedTypes = Set.of("PushEvent", "IssuesEvent", "PullRequestEvent");
        return apiEvents.stream()
                .map(event -> (String) event.get("type"))
                .anyMatch(allowedTypes::contains);
    }


    // ============================================================
    // 9. 공통 헬퍼 메서드
    // ============================================================

    /**
     * 1. 메서드 설명: 주어진 access token과 mediaType을 기반으로 HTTP 헤더를 생성하는 헬퍼 메서드.
     * 2. 로직:
     *    - HttpHeaders 객체를 생성한 후, Bearer 인증 방식으로 access token을 설정하고,
     *      JSON 형식의 응답을 수락하도록 Accept 헤더를 추가한다.
     * 3. param:
     *      accessToken - GitHub API 접근에 사용되는 access token.
     *      mediaType   - 응답으로 수락할 미디어 타입.
     * 4. return: 설정된 HttpHeaders 객체.
     */
    private HttpHeaders createHeaders(String accessToken, MediaType mediaType) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        headers.setAccept(Collections.singletonList(mediaType));
        return headers;
    }

    /**
     * 1. 메서드 설명: 지정된 URL과 요청 객체를 사용하여 API 호출 후 응답을 List<Map<String, Object>> 형태로 반환하는 헬퍼 메서드.
     * 2. 로직:
     *    - restTemplate.exchange()를 호출한 후 응답 상태가 2xx가 아니면 예외를 발생시키고,
     *      본문이 null이면 빈 리스트를 반환한다.
     * 3. param:
     *      url     - API 호출 URL.
     *      request - HTTP 요청 객체.
     * 4. return: 응답 데이터를 포함한 List<Map<String, Object>> 객체.
     */
    private List<Map<String, Object>> fetchApiResponseList(String url, HttpEntity<String> request) {
        ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                request,
                new ParameterizedTypeReference<List<Map<String, Object>>>() {}
        );
        if (!response.getStatusCode().is2xxSuccessful()) {
            throw new GithubRepositoryNotFoundException("Failed to fetch API response - HTTP " + response.getStatusCode());
        }
        return Optional.ofNullable(response.getBody()).orElse(Collections.emptyList());
    }
}

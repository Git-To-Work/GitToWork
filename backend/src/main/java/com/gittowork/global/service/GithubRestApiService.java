package com.gittowork.global.service;

import com.gittowork.domain.github.entity.GithubCommit;
import com.gittowork.domain.github.entity.GithubRepository;
import com.gittowork.domain.github.entity.Repository;
import com.gittowork.domain.github.repository.GithubRepoRepository;
import com.gittowork.global.exception.GithubRepositoryNotFoundException;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class GithubRestApiService {

    private final GithubRepoRepository githubRepoRepository;
    @Value("${github.client.id}")
    private String clientId;

    @Value("${github.client.secret}")
    private String clientSecret;

    @Value("${github.redirect.uri}")
    private String redirectUri;

    private final RestTemplate restTemplate;

    @Autowired
    public GithubRestApiService(RestTemplate restTemplate, GithubRepoRepository githubRepoRepository) {
        this.restTemplate = restTemplate;
        this.githubRepoRepository = githubRepoRepository;
    }

    /**
     * 1. 메서드 설명: GitHub OAuth 인증 과정에서 전달받은 code를 사용하여 access token 정보를 가져오는 API.
     * 2. 로직:
     *    - 요청 헤더에 JSON 형식의 응답을 수락하도록 설정한다.
     *    - 요청 본문에 client_id, client_secret, redirect_uri, code를 추가한다.
     *    - GitHub OAuth access token URL에 POST 요청을 보내 access token 정보를 포함한 응답을 받는다.
     *    - 응답으로 받은 access token 정보를 Map 형태로 반환한다.
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

        return response.getBody();
    }

    /**
     * 1. 메서드 설명: GitHub API를 호출하여 access token 기반으로 사용자 정보를 조회하는 API.
     * 2. 로직:
     *    - 요청 헤더에 bearer 토큰 방식으로 access token을 설정하고, JSON 형식의 응답을 수락하도록 설정한다.
     *    - GitHub 사용자 정보 API에 GET 요청을 보내 사용자 정보를 조회한다.
     *    - 응답으로 받은 사용자 정보를 Map 형태로 반환한다.
     * 3. param: accessToken - GitHub API 접근에 사용되는 access token.
     * 4. return: GitHub 사용자 정보를 포함한 Map 객체.
     */
    public Map<String, Object> getUserInfo(String accessToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));

        HttpEntity<String> request = new HttpEntity<>(headers);

        ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                "https://api.github.com/user",
                HttpMethod.GET,
                request,
                new ParameterizedTypeReference<Map<String, Object>>() {}
        );

        return response.getBody();
    }

    /**
     * 1. 메서드 설명: GitHub API를 호출하여 사용자의 repository 정보를 조회하고, 이를 데이터베이스에 저장하는 비동기 API.
     * 2. 로직:
     *    - 요청 헤더에 bearer 토큰 방식으로 access token을 설정하고, JSON 형식의 응답을 수락하도록 설정한다.
     *    - GitHub 사용자 repository API에 GET 요청을 보내 해당 사용자의 repository 목록을 조회한다.
     *    - 조회된 repository 정보가 없을 경우 GithubRepositoryNotFoundException 예외를 발생시킨다.
     *    - 각 repository 정보를 Repository 객체로 변환한 후, 리스트에 추가한다.
     *    - 사용자 ID와 repository 리스트를 포함하는 GithubRepository 엔티티를 생성하여 데이터베이스에 저장한다.
     * 3. param:
     *      accessToken - GitHub API 접근에 사용되는 access token.
     *      githubName - GitHub 사용자 이름.
     *      userId - 현재 애플리케이션 사용자 ID.
     * 4. return: 없음 (비동기 처리를 수행하며 결과를 반환하지 않음).
     */
    private void saveUserGithubRepository(String accessToken, String githubName, int userId) {
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));

        HttpEntity<String> request = new HttpEntity<>(headers);

        ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                "https://api.github.com/users/{githubName}/repos",
                HttpMethod.GET,
                request,
                new ParameterizedTypeReference<List<Map<String, Object>>>() {},
                githubName
        );

        List<Map<String, Object>> responseBody = response.getBody();

        if (responseBody == null) {
            throw new GithubRepositoryNotFoundException("Github repository not found");
        }

        List<Repository> repositories = responseBody.stream()
                .map(map -> Repository.builder()
                        .repoId((Integer) map.get("id"))
                        .repoName(map.get("name").toString())
                        .fullName(map.get("full_name").toString())
                        .language(map.get("language").toString())
                        .stargazersCount((Integer) map.get("stargazers_count"))
                        .forksCount((Integer) map.get("forks_count"))
                        .createdAt(LocalDateTime.parse(map.get("created_at").toString()))
                        .updatedAt(LocalDateTime.parse(map.get("updated_at").toString()))
                        .pushedAt(LocalDateTime.parse(map.get("pushed_at").toString()))
                        .description(map.get("description").toString())
                        .build())
                .collect(Collectors.toList());

        GithubRepository githubRepository = GithubRepository.builder()
                .userId(userId)
                .repositories(repositories)
                .build();

        githubRepoRepository.save(githubRepository);
    }

//    private void saveUserGithubCommits(String accessToken, String githubName, int userId) {
//        HttpHeaders headers = new HttpHeaders();
//        headers.setBearerAuth(accessToken);
//        headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));
//
//        HttpEntity<String> request = new HttpEntity<>(headers);
//
//        List<Repository> repositories = githubRepoRepository.findByUserId(userId)
//                .orElseThrow(() -> new GithubRepositoryNotFoundException("Github repository not found"))
//                .getRepositories();
//
//        for (Repository repository : repositories) {
//            String repositoryName = repository.getRepoName();
//
//            ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
//                    "https://api.github.com/repos/{githubName}/{repositoryName}/commits",
//                    HttpMethod.GET,
//                    request,
//                    new ParameterizedTypeReference<List<Map<String, Object>>>() {},
//                    githubName,
//                    repositoryName
//            );
//
//            List<Map<String, Object>> responseBody = response.getBody();
//
//
//            if (responseBody == null) {
//                throw new GithubRepositoryNotFoundException("Github repository not found");
//            }
//
//
//
//            GithubCommit githubCommit = GithubCommit.builder()
//                    .userId(userId)
//                    .repoId((Integer) responseBody.get("repo_id"))
//                    .commits()
//                    .build();
//        }
//    }
}

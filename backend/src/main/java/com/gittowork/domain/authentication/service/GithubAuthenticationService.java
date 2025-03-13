package com.gittowork.domain.authentication.service;

import com.gittowork.domain.authentication.dto.response.SignInGithubResponse;
import com.gittowork.domain.user.entity.User;
import com.gittowork.domain.user.repository.UserRepository;
import com.gittowork.global.exception.GithubSignInException;
import lombok.Getter;
import lombok.Setter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.util.Collections;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

@Service
public class GithubAuthenticationService {

    @Value("${github.client.id}")
    private String clientId;

    @Value("${github.client.secret}")
    private String clientSecret;

    @Value("${github.redirect.uri}")
    private String redirectUri;

    private final UserRepository userRepository;

    @Autowired
    public GithubAuthenticationService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Getter
    @Setter
    private static class GithubUser {
        private String login;      // GitHub 로그인 아이디
        private int id;           // GitHub user id
        private String avatar_url;
        private String name;
    }


    /**
     * https://github.com/login/oauth/access_token 주소로 github access_token 요청
     *
     * @param code 프론트엔드에서 넘어온 code
     * @return githubAccessToken
     */
    private String getAccessToken(String code) {
        RestTemplate restTemplate = new RestTemplate();

        HttpHeaders headers = new HttpHeaders();
        headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));

        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("client_id", clientId);
        body.add("client_secret", clientSecret);
        body.add("redirect_uri", redirectUri);
        body.add("code", code);

        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(body, headers);

        String accessTokenUrl = "https://github.com/login/oauth/access_token";

        ResponseEntity<Map> response = restTemplate.postForEntity(accessTokenUrl, request, Map.class);
        Map<String, Object> responseBody = response.getBody();

        if (Objects.isNull(responseBody) || !responseBody.containsKey("access_token")) {
            throw new GithubSignInException("Unauthorized or Invalid Code.");
        }

        return responseBody.get("access_token").toString();
    }

    private GithubUser getUserInfo(String accessToken) {
        RestTemplate restTemplate = new RestTemplate();

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));

        HttpEntity<String> request = new HttpEntity<>(headers);

        ResponseEntity<GithubUser> response = restTemplate.exchange(
                "https://api.github.com/user",
                HttpMethod.GET,
                request,
                GithubUser.class
        );

        return response.getBody();
    }

    public SignInGithubResponse signInGithub(String code) {
        String githubAccessToken = getAccessToken(code);
        GithubUser githubUserInfo = getUserInfo(githubAccessToken);

        Optional<User> user = userRepository.findByEmail(githubUserInfo.getLogin());

        return null;
    }
}

package com.gittowork.domain.authentication.dto.response;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SignInGithubResponse {
    private String email;
    private String nickname;
    private boolean privacyPolicyAgreed;
    private String avatarUrl;
    private String accessToken;
}

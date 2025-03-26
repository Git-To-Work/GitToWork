package com.gittowork.domain.github.dto.response;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateGithubAnalysisByRepositoryResponse {
    private boolean analysisStarted;
    private String message;
}

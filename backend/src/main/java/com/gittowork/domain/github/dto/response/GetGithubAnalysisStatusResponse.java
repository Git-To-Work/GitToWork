package com.gittowork.domain.github.dto.response;

import com.gittowork.domain.github.entity.AnalysisStatus;
import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GetGithubAnalysisStatusResponse {
    private String status;
    private String selectedRepositoryId;
    private List<String> selectedRepositories;
    private String message;
}

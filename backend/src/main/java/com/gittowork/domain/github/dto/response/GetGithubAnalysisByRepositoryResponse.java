package com.gittowork.domain.github.dto.response;

import com.gittowork.domain.github.model.analysis.AIAnalysis;
import com.gittowork.domain.github.model.analysis.ActivityMetrics;
import com.gittowork.domain.github.model.analysis.Stats;
import lombok.*;

import java.util.List;
import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GetGithubAnalysisByRepositoryResponse {
    private String analysisDate;
    private Map<String, Double> languageRatios;
    private Map<String, Integer> languageLevel;
    private List<String> selectedRepositories;
    private String overallScore;
    private ActivityMetrics activityMetrics;
    private AIAnalysis aiAnalysis;
}

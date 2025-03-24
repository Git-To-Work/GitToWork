package com.gittowork.domain.github.entity;

import lombok.*;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Document
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GithubAnalysisResult {
    private long userId;
    private LocalDateTime analysisDate;
    private long selectedRepositoriesId;
    private List<String> selectedRepositories;
    private Map<String, Double> languageRatios;

    // 각 Repository에 대한 분석 결과 목록
    private List<SonarRepositoryResult> repositories;

    // 전체 분석 점수 및 역할 관련 정보
    private int overallScore;
    private String primaryRole;
    private Map<String, Integer> roleScores;
    private SonarActivityMetrics activityMetrics;

    // AI 기반 분석 결과 및 피드백
    private SonarAIAnalysis aiAnalysis;
    private String aiFeedback;
}

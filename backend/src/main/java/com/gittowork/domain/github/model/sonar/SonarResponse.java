package com.gittowork.domain.github.model.sonar;

import com.gittowork.domain.github.model.analysis.AIAnalysis;
import com.gittowork.domain.github.model.analysis.ActivityMetrics;
import lombok.*;

import java.util.Map;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SonarResponse {

    private ProjectStatus projectStatus;
    private Map<String, Double> languageDistribution;
    private double coverage;
    private int bugCount;
    private String primaryRole;
    private Map<String, Integer> roleScores;
    private ActivityMetrics activityMetrics;
    private AIAnalysis aiAnalysis;
    private String aiFeedback;
    private String errorMessage;

    public boolean isSuccessful() {
        return projectStatus != null && "OK".equalsIgnoreCase(projectStatus.getStatus());
    }

    public boolean isError() {
        return errorMessage != null && !errorMessage.isEmpty();
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Condition {
        private String metricKey;
        private String comparator;
        private String errorThreshold;
        private String actualValue;
        private String status;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Period {
        private int index;
        private String mode;
        private String date;
    }
}

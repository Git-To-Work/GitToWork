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

    /**
     * SonarQube API 응답 중 quality gate 관련 정보를 포함하는 필드
     */
    private ProjectStatus projectStatus;

    /**
     * 언어별 코드 라인 수 정보 (예: {"Java": 15000.0, "XML": 5000.0})
     */
    private Map<String, Double> languageDistribution;

    /**
     * 전체 코드 커버리지 (예: 75.0 -> 75%)
     */
    private double coverage;

    /**
     * 버그 건수 (예: 0)
     */
    private int bugCount;

    /**
     * 프로젝트 분석 결과에서 추출한 주요 역할 정보 (필요 시)
     */
    private String primaryRole;

    /**
     * 역할별 점수 정보 (예: {"Backend": 80, "Frontend": 70})
     */
    private Map<String, Integer> roleScores;

    /**
     * SonarQube에서 제공하는 활동 메트릭 (예: commit 수, PR 참여 등)
     */
    private ActivityMetrics activityMetrics;

    /**
     * SonarQube AI 분석 결과 (요약, 개선점 제안 등)
     */
    private AIAnalysis aiAnalysis;

    /**
     * 추가 AI 피드백 텍스트
     */
    private String aiFeedback;

    /**
     * 에러 발생 시 메시지 (비어 있으면 정상으로 판단)
     */
    private String errorMessage;

    /**
     * 분석이 성공적으로 완료되었는지 여부 판단
     */
    public boolean isSuccessful() {
        // projectStatus가 존재하고, 상태가 "OK"인 경우 성공으로 간주
        return projectStatus != null && "OK".equalsIgnoreCase(projectStatus.getStatus());
    }

    /**
     * 분석 결과에서 에러가 발생했는지 여부
     */
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
        /**
         * 기간 인덱스 (예: 1)
         */
        private int index;
        /**
         * 기간 모드 (예: "previous_version")
         */
        private String mode;
        /**
         * 날짜 정보 (예: "2020-09-15T12:45:32+0000")
         */
        private String date;
    }
}

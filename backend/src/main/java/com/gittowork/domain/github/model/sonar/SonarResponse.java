package com.gittowork.domain.github.model.sonar;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.gittowork.domain.github.model.analysis.AIAnalysis;
import com.gittowork.domain.github.model.analysis.ActivityMetrics;
import lombok.*;

import java.util.List;
import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SonarResponse {

    private Component component;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Component {
        private String key;
        private String name;
        private String qualifier;
        private List<Measure> measures;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Measure {
        private String metric;
        private String value;
    }
}

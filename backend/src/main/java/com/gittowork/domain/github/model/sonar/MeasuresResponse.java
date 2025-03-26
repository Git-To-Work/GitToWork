package com.gittowork.domain.github.model.sonar;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MeasuresResponse {
    private Component component;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Component {
        private String key;
        private String name;
        private List<Measure> measures;
    }
}

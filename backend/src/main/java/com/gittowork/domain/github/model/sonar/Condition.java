package com.gittowork.domain.github.model.sonar;

import lombok.*;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Condition {

    private String metricKey;

    private String comparator;

    private String errorThreshold;

    private String actualValue;

    private String status;
}

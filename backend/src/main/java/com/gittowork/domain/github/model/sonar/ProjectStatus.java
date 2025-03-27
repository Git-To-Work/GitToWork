package com.gittowork.domain.github.model.sonar;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProjectStatus {

    private String status;

    private List<SonarResponse.Condition> conditions;

    private List<SonarResponse.Period> periods;

    private List<SonarResponse.Condition> ignoredConditions;
}

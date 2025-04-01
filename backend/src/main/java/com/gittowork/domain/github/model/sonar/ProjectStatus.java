package com.gittowork.domain.github.model.sonar;

import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.gittowork.global.deserializer.ConditionListDeserializer;
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

    // ignoredConditions 필드에 커스텀 deserializer 적용
    @JsonDeserialize(using = ConditionListDeserializer.class)
    private List<SonarResponse.Condition> ignoredConditions;
}


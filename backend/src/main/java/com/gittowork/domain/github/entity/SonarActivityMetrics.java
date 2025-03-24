package com.gittowork.domain.github.entity;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SonarActivityMetrics {
    private int totalCommits;
    private int prParticipation;
    private int issueComments;
}

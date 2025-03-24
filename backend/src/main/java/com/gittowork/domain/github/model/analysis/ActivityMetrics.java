package com.gittowork.domain.github.model.analysis;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ActivityMetrics {
    private int totalCommits;
    private int prParticipation;
    private int issueComments;
}

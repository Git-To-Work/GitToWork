package com.gittowork.domain.github.entity;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SonarStats {
    private int stargazersCount;
    private int commitCount;
    private int prCount;
    private int issueCount;
}

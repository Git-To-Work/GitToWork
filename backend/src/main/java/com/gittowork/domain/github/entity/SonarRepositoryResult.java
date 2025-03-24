package com.gittowork.domain.github.entity;

import lombok.*;

import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SonarRepositoryResult {
    private String repoId;
    private int score;
    private String insights;
    private Map<String, Integer> languages;
    private SonarStats stats;
    private int commitFrequency;
    private Map<String, Integer> languageLevel;
}

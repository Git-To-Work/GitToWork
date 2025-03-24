package com.gittowork.domain.github.entity;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SonarAIAnalysis {
    private List<String> analysisSummary;
    private List<String> improvementSuggestions;
}

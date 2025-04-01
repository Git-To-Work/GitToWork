package com.gittowork.domain.github.model.analysis;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@ToString
public class AIAnalysis {
    private List<String> analysisSummary;
    private List<String> improvementSuggestions;
}

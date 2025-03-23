package com.gittowork.domain.github.entity;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GithubIssueLabel {
    private int id;
    private String name;
    private String color;
    private String description;
}

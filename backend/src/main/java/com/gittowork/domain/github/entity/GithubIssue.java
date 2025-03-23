package com.gittowork.domain.github.entity;

import jakarta.persistence.Id;
import lombok.*;
import org.springframework.data.mongodb.core.mapping.Document;

import java.util.List;

@Document
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GithubIssue {
    @Id
    private String githubIssueId;

    private int repoId;

    private long issueId;

    private String url;

    private String commentsUrl;

    private String title;

    private String body;

    private GithubIssueUser user;

    private List<GithubIssueLabel> labels;

    private GithubIssueUser assignee;

    private List<GithubIssueUser> assignees;

    private int comments;
}


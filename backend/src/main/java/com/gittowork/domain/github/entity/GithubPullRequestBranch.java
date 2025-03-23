package com.gittowork.domain.github.entity;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GithubPullRequestBranch {

    private String label;

    private String ref;

    private String sha;

    private GithubPullRequestUser user;
}
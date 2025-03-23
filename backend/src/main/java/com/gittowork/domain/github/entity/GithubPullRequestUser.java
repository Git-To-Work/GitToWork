package com.gittowork.domain.github.entity;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GithubPullRequestUser {
    private String login;
    private int id;
}

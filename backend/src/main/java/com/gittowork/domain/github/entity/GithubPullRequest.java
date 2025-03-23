package com.gittowork.domain.github.entity;

import jakarta.persistence.Id;
import lombok.*;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "github_pull_requests")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GithubPullRequest {

    @Id
    private String id;  // MongoDB Document ID (자동 생성 혹은 직접 설정 가능)

    private String repoId;

    private int prId;

    private String url;

    private String htmlUrl;

    private String diffUrl;

    private String patchUrl;

    private String title;

    private String body;

    private int commentsCount;

    private int reviewCommentsCount;

    private int commitsCount;

    private GithubPullRequestUser user;

    private GithubPullRequestBranch head;

    private GithubPullRequestBranch base;

}

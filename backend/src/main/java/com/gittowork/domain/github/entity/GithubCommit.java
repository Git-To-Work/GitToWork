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
public class GithubCommit {

    @Id
    private String githubCommitId;

    private int userId;

    private int repoId;

    private List<Commit> commits;
}

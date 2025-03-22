package com.gittowork.domain.github.entity;

import lombok.Data;
import org.springframework.data.mongodb.core.mapping.Field;

import java.time.LocalDateTime;

@Data
public class Repository {
    @Field("repo_id")
    private int repoId;

    @Field("repo_name")
    private String repoName;

    @Field("full_name")
    private String fullName;

    private String language;

    @Field("stargazers_count")
    private int stargazersCount;

    @Field("forks_count")
    private int forksCount;

    @Field("created_at")
    private LocalDateTime createdAt;

    @Field("updated_at")
    private LocalDateTime updatedAt;

    @Field("pushed_at")
    private LocalDateTime pushedAt;

    private String description;
}

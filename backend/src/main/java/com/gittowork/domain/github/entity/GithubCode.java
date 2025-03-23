package com.gittowork.domain.github.entity;

import jakarta.persistence.Id;
import lombok.*;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GithubCode {

    @Id
    private String githubCodeId;

    private int userId;

    private int repoId;

    private String commitSha;

    private LocalDateTime commitDate;

    private String fileName;

    private String codeContent;

}

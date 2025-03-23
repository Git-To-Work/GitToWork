package com.gittowork.domain.github.entity;

import jakarta.persistence.Id;
import lombok.*;
import org.springframework.data.mongodb.core.mapping.Document;

@Document
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GithubEvent {

    @Id
    private String githubEventId;

    private int userId;

    private Event events;
}

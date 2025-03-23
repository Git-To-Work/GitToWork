package com.gittowork.domain.github.entity;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Event {

    private String eventType;

    private String repo;

    private LocalDateTime createdAt;

}

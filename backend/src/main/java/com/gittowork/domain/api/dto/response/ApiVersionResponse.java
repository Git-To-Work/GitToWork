package com.gittowork.domain.api.dto.response;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ApiVersionResponse {
    private String version;
    private String releaseDate;
}

package com.gittowork.domain.user.dto.response;

import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GetMyInterestFieldResponse {

    private String[] interestsFields;
}

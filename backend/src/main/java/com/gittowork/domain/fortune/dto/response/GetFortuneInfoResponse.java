package com.gittowork.domain.fortune.dto.response;

import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GetFortuneInfoResponse {
    private String birthDt;
    private String sex;
    private String birthTm;
}

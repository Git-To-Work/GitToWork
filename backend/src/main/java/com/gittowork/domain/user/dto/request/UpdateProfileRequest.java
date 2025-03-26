package com.gittowork.domain.user.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import javax.validation.constraints.Size;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateProfileRequest {

    @NotNull
    private int userId;

    @NotNull
    private String name;

    @NotNull
    private String birthDt;

    @NotNull
    private int experience;

    @NotNull
    private String phone;

    @NotNull
    @Size(max = 5)
    private int[] interestsFields;
}

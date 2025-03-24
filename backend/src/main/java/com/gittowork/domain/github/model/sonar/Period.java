package com.gittowork.domain.github.model.sonar;

import lombok.*;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Period {

    private int index;

    private String mode;

    private String date;
}

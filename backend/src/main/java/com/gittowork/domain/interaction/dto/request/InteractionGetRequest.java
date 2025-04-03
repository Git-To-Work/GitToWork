package com.gittowork.domain.interaction.dto.request;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InteractionGetRequest {
    public int page = 0;
    public int size = 20;

}

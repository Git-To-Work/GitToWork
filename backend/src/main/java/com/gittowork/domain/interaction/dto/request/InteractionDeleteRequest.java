package com.gittowork.domain.interaction.dto.request;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InteractionDeleteRequest {
    private int companyId;
}

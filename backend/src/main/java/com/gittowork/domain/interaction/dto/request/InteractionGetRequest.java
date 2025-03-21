package com.gittowork.domain.interaction.dto.request;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class InteractionGetRequest {
    public int page = 0;
    public int size = 20;

}

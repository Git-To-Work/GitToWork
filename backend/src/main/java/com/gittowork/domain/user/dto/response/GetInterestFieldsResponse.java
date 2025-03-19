package com.gittowork.domain.user.dto.response;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GetInterestFieldsResponse {

    private List<Field> fields;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    static class Field {
        private int fieldId;
        private String fieldName;
        private String logoUrl;
    }

}

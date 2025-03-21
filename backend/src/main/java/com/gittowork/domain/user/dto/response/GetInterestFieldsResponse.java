package com.gittowork.domain.user.dto.response;

import com.gittowork.domain.fields.entity.Fields;
import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GetInterestFieldsResponse {

    private List<Fields> fields;

}

package com.gittowork.domain.interaction.dto.response;

import com.gittowork.domain.company.entity.Company;
import lombok.*;

import java.util.List;

@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CompanyInteractionResponse {
    private List<Company> companies;
    private Pagination pagination;
}

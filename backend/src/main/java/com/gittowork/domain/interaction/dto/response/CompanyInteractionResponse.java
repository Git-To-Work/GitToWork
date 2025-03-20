package com.gittowork.domain.interaction.dto.response;

import com.gittowork.domain.company.entity.Company;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CompanyInteractionResponse {
    private List<Company> companies;
    private Pagination pagination;
}

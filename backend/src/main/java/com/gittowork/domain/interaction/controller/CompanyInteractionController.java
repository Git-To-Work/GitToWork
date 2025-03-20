package com.gittowork.domain.interaction.controller;

import com.gittowork.domain.interaction.dto.request.InteractionAddRequest;
import com.gittowork.domain.interaction.dto.request.InteractionDeleteRequest;
import com.gittowork.domain.interaction.dto.request.InteractionGetRequest;
import com.gittowork.domain.interaction.service.CompanyInteractionService;
import com.gittowork.global.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/company-interaction")
@RequiredArgsConstructor
public class CompanyInteractionController {
    private final CompanyInteractionService companyInteractionService;

    @GetMapping("/select/scrap")
    public ApiResponse<?> getScrapCompanies(InteractionGetRequest interactionGetRequest) {
        return companyInteractionService.getScrapCompanies(interactionGetRequest);
    }

    @PostMapping("/create/scrap")
    public ApiResponse<?> addScrapCompanies(InteractionAddRequest interactionAddRequest) {
        return companyInteractionService.addScrapCompanies(interactionAddRequest);
    }

    @DeleteMapping("/delete/scrap")
    public ApiResponse<?> deleteScrapCompanies(InteractionDeleteRequest interactionDeleteRequest) {
        return companyInteractionService.deleteScrapCompanies(interactionDeleteRequest);
    }

    @GetMapping("/select/like")
    public ApiResponse<?> getMyLikeCompanies(InteractionGetRequest interactionGetRequest) {
        return companyInteractionService.getMyLikeCompanies(interactionGetRequest);
    }

    @PostMapping("/create/like")
    public ApiResponse<?> addLikeCompanies(InteractionAddRequest interactionAddRequest) {
        return companyInteractionService.addLikeCompanies(interactionAddRequest);
    }

    @DeleteMapping("/delete/like")
    public ApiResponse<?> deleteLikeCompanies(InteractionDeleteRequest interactionDeleteRequest) {
        return companyInteractionService.deleteLikeCompanies(interactionDeleteRequest);
    }

    @GetMapping("/select/blacklist")
    public ApiResponse<?> getMyBlackList(InteractionGetRequest interactionGetRequest) {
        return companyInteractionService.getMyBlackList(interactionGetRequest);
    }

    @PostMapping("/create/blacklist")
    public ApiResponse<?> addMyBlackList(InteractionAddRequest interactionAddRequest) {
        return companyInteractionService.addMyBlackList(interactionAddRequest);

    }

    @DeleteMapping("/delete/blacklist")
    public ApiResponse<?> deleteMyBlackList(InteractionDeleteRequest interactionDeleteRequest) {
        return companyInteractionService.deleteMyBlackList(interactionDeleteRequest);
    }
}

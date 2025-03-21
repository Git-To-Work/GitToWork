package com.gittowork.domain.interaction.controller;

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
        return ApiResponse.success(companyInteractionService.getScrapCompanies(interactionGetRequest));
    }

    @PostMapping("/create/scrap")
    public ApiResponse<?> addScrapCompanies(@RequestParam int companyId) {
        return ApiResponse.success(companyInteractionService.addScrapCompanies(companyId));
    }

    @DeleteMapping("/delete/scrap")
    public ApiResponse<?> deleteScrapCompanies(@RequestParam int companyId) {
        return ApiResponse.success(companyInteractionService.deleteScrapCompanies(companyId));
    }

    @GetMapping("/select/like")
    public ApiResponse<?> getMyLikeCompanies(InteractionGetRequest interactionGetRequest) {
        return ApiResponse.success(companyInteractionService.getMyLikeCompanies(interactionGetRequest));
    }

    @PostMapping("/create/like")
    public ApiResponse<?> addLikeCompanies(@RequestParam int companyId) {
        return ApiResponse.success(companyInteractionService.addLikeCompanies(companyId));
    }

    @DeleteMapping("/delete/like")
    public ApiResponse<?> deleteLikeCompanies(@RequestParam int companyId) {
        return ApiResponse.success(companyInteractionService.deleteLikeCompanies(companyId));
    }

    @GetMapping("/select/blacklist")
    public ApiResponse<?> getMyBlackList(InteractionGetRequest interactionGetRequest) {
        return ApiResponse.success(companyInteractionService.getMyBlackList(interactionGetRequest));
    }

    @PostMapping("/create/blacklist")
    public ApiResponse<?> addMyBlackList(@RequestParam int companyId) {
        return ApiResponse.success(companyInteractionService.addMyBlackList(companyId));

    }

    @DeleteMapping("/delete/blacklist")
    public ApiResponse<?> deleteMyBlackList(@RequestParam int companyId) {
        return ApiResponse.success(companyInteractionService.deleteMyBlackList(companyId));
    }
}

package com.gittowork.domain.interaction.controller;

import com.gittowork.domain.interaction.dto.request.InteractionGetRequest;
import com.gittowork.domain.interaction.service.CompanyInteractionService;
import com.gittowork.global.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/company-interaction")
@RequiredArgsConstructor
@Tag(name = "Company Interaction", description = "유저-회사 상호작용 관련 API")
public class CompanyInteractionController {
    private final CompanyInteractionService companyInteractionService;

    @Operation(summary = "스크랩한 회사 목록 조회", description = "현재 인증된 사용자가 스크랩한 회사 목록을 조회합니다.")
    @GetMapping("/select/scrap")
    public ApiResponse<?> getScrapCompany(InteractionGetRequest interactionGetRequest) {
        return ApiResponse.success(companyInteractionService.getScrapCompany(interactionGetRequest));
    }

    @Operation(summary = "회사 스크랩 추가", description = "현재 인증된 사용자가 특정 회사를 스크랩 목록에 추가합니다.")
    @PostMapping("/create/scrap")
    public ApiResponse<?> addScrapCompany(@RequestParam int companyId) {
        return ApiResponse.success(companyInteractionService.addScrapCompany(companyId));
    }

    @Operation(summary = "회사 스크랩 삭제", description = "현재 인증된 사용자의 스크랩 목록에서 특정 회사를 삭제합니다.")
    @DeleteMapping("/delete/scrap")
    public ApiResponse<?> deleteScrapCompany(@RequestParam int companyId) {
        return ApiResponse.success(companyInteractionService.deleteScrapCompany(companyId));
    }

    @Operation(summary = "좋아요한 회사 목록 조회", description = "현재 인증된 사용자가 좋아요한 회사 목록을 조회합니다.")
    @GetMapping("/select/like")
    public ApiResponse<?> getMyLikeCompany(InteractionGetRequest interactionGetRequest) {
        return ApiResponse.success(companyInteractionService.getMyLikeCompany(interactionGetRequest));
    }

    @Operation(summary = "회사 좋아요 추가", description = "현재 인증된 사용자가 특정 회사를 좋아요 목록에 추가합니다.")
    @PostMapping("/create/like")
    public ApiResponse<?> addLikeCompany(@RequestParam int companyId) {
        return ApiResponse.success(companyInteractionService.addLikeCompany(companyId));
    }

    @Operation(summary = "회사 좋아요 삭제", description = "현재 인증된 사용자의 좋아요 목록에서 특정 회사를 삭제합니다.")
    @DeleteMapping("/delete/like")
    public ApiResponse<?> deleteLikeCompany(@RequestParam int companyId) {
        return ApiResponse.success(companyInteractionService.deleteLikeCompany(companyId));
    }

    @Operation(summary = "블랙리스트 회사 목록 조회", description = "현재 인증된 사용자가 블랙리스트에 등록한 회사 목록을 조회합니다.")
    @GetMapping("/select/blacklist")
    public ApiResponse<?> getMyBlackList(InteractionGetRequest interactionGetRequest) {
        return ApiResponse.success(companyInteractionService.getMyBlackList(interactionGetRequest));
    }

    @Operation(summary = "블랙리스트 회사 추가", description = "현재 인증된 사용자가 특정 회사를 블랙리스트에 추가합니다.")
    @PostMapping("/create/blacklist")
    public ApiResponse<?> addMyBlackList(@RequestParam int companyId) {
        return ApiResponse.success(companyInteractionService.addMyBlackList(companyId));
    }

    @Operation(summary = "블랙리스트 회사 삭제", description = "현재 인증된 사용자의 블랙리스트에서 특정 회사를 삭제합니다.")
    @DeleteMapping("/delete/blacklist")
    public ApiResponse<?> deleteMyBlackList(@RequestParam int companyId) {
        return ApiResponse.success(companyInteractionService.deleteMyBlackList(companyId));
    }
}

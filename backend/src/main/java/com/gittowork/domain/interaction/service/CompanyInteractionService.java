package com.gittowork.domain.interaction.service;

import com.gittowork.domain.company.entity.Company;
import com.gittowork.domain.company.repository.CompanyRepository;
import com.gittowork.domain.interaction.dto.request.InteractionAddRequest;
import com.gittowork.domain.interaction.dto.request.InteractionDeleteRequest;
import com.gittowork.domain.interaction.dto.request.InteractionGetRequest;
import com.gittowork.domain.interaction.dto.response.CompanyInteractionResponse;
import com.gittowork.domain.interaction.dto.response.Pagination;
import com.gittowork.domain.interaction.entity.*;
import com.gittowork.domain.interaction.repository.UserBlacklistRepository;
import com.gittowork.domain.interaction.repository.UserLikesRepository;
import com.gittowork.domain.interaction.repository.UserScrapsRepository;
import com.gittowork.domain.user.entity.User;
import com.gittowork.domain.user.repository.UserRepository;
import com.gittowork.global.exception.CompanyNotFoundException;
import com.gittowork.global.exception.InteractionDuplicateException;
import com.gittowork.global.exception.UserInteractionNotFoundException;
import com.gittowork.global.exception.UserNotFoundException;
import com.gittowork.global.response.ApiResponse;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CompanyInteractionService {

    private final UserRepository userRepository;
    private final CompanyRepository companyRepository;
    private final UserLikesRepository userLikesRepository;
    private final UserScrapsRepository userScrapsRepository;
    private final UserBlacklistRepository userBlacklistRepository;

    @Transactional
    public ApiResponse<?> getScrapCompanies(InteractionGetRequest interactionGetRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String githubName = authentication.getName();

        int userId = userRepository.findByGithubName(githubName)
                .orElseThrow(() -> new UserNotFoundException(githubName))
                .getId();

        Pageable pageable = PageRequest.of(interactionGetRequest.getPage(), interactionGetRequest.getSize());

        Page<UserScraps> userScraps = userScrapsRepository.findByUserId(userId, pageable);

        List<Company> companies = userScraps.stream()
                .map(UserScraps::getCompany)
                .collect(Collectors.toList());

        CompanyInteractionResponse companyInteractionResponse = CompanyInteractionResponse
                .builder()
                .companies(companies)
                .pagination(new Pagination(userScraps.getNumber(), userScraps.getSize(), userScraps.getTotalPages(), userScraps.getTotalElements()))
                .build();

        ApiResponse<?> apiResponse = ApiResponse
                .builder()
                .status(200)
                .code("SU")
                .results(companyInteractionResponse)
                .message("OK")
                .build();

        return apiResponse;
    }

    @Transactional
    public ApiResponse<?> addScrapCompanies(InteractionAddRequest interactionAddRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String githubName = authentication.getName();

        User user = userRepository.findByGithubName(githubName).orElseThrow(() -> new UserNotFoundException(githubName));

        Company company = companyRepository.findById(interactionAddRequest.getCompanyId()).orElseThrow(() -> new CompanyNotFoundException("Company not found"));

        UserScrapsId userScrapsId = new UserScrapsId(user.getId(), company.getId());

        if (userScrapsRepository.existsById(userScrapsId)) {
            throw new InteractionDuplicateException("Already Exists");
        }

        UserScraps userScraps = UserScraps
                .builder()
                .id(userScrapsId)
                .user(user)
                .company(company)
                .build();

        userScrapsRepository.save(userScraps);

        return ApiResponse.success(HttpStatus.OK);
    }

    @Transactional
    public ApiResponse<?> deleteScrapCompanies(InteractionDeleteRequest interactionDeleteRequest){
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String githubName = authentication.getName();

        User user = userRepository.findByGithubName(githubName).orElseThrow(() -> new UserNotFoundException(githubName));

        Company company = companyRepository.findById(interactionDeleteRequest.getCompanyId()).orElseThrow(() -> new CompanyNotFoundException("Company not found"));

        UserScrapsId userScrapsId = new UserScrapsId();
        userScrapsId.setUserId(user.getId());
        userScrapsId.setCompanyId(company.getId());

        UserScraps userScraps = userScrapsRepository.findById(userScrapsId)
                .orElseThrow(() -> new UserInteractionNotFoundException("UserScraps Not Found"));

        userScrapsRepository.delete(userScraps);

        return ApiResponse.success(HttpStatus.OK);
    }

    @Transactional
    public ApiResponse<?> getMyLikeCompanies(InteractionGetRequest interactionGetRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String githubName = authentication.getName();

        int userId = userRepository.findByGithubName(githubName)
                .orElseThrow(() -> new UserNotFoundException(githubName))
                .getId();

        Pageable pageable = PageRequest.of(interactionGetRequest.getPage(), interactionGetRequest.getSize());

        Page<UserLikes> userLikes = userLikesRepository.findByUserId(userId, pageable);


        List<Company> companies = userLikes.stream()
                .map(UserLikes::getCompany)
                .collect(Collectors.toList());

        CompanyInteractionResponse companyInteractionResponse = CompanyInteractionResponse
                .builder()
                .companies(companies)
                .pagination(new Pagination(userLikes.getNumber(), userLikes.getSize(), userLikes.getTotalPages(), userLikes.getTotalElements()))
                .build();

        ApiResponse<?> apiResponse = ApiResponse
                .builder()
                .status(200)
                .code("SU")
                .results(companyInteractionResponse)
                .message("OK")
                .build();

        return apiResponse;
    }

    @Transactional
    public ApiResponse<?> addLikeCompanies(InteractionAddRequest interactionAddRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String githubName = authentication.getName();

        User user = userRepository.findByGithubName(githubName).orElseThrow(() -> new UserNotFoundException(githubName));

        Company company = companyRepository.findById(interactionAddRequest.getCompanyId()).orElseThrow(() -> new CompanyNotFoundException("Company not found"));

        UserLikesId userLikesId = new UserLikesId(user.getId(), company.getId());

        if (userLikesRepository.existsById(userLikesId)) {
            throw new InteractionDuplicateException("Already Exists");
        }

        UserLikes userLikes = UserLikes
                .builder()
                .id(userLikesId)
                .user(user)
                .company(company)
                .build();

        userLikesRepository.save(userLikes);

        return ApiResponse.success(HttpStatus.OK);
    }

    @Transactional
    public ApiResponse<?> deleteLikeCompanies(InteractionDeleteRequest interactionDeleteRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String githubName = authentication.getName();

        User user = userRepository.findByGithubName(githubName).orElseThrow(() -> new UserNotFoundException(githubName));

        Company company = companyRepository.findById(interactionDeleteRequest.getCompanyId()).orElseThrow(() -> new CompanyNotFoundException("Company not found"));

        UserLikesId userLikesId = new UserLikesId(user.getId(), company.getId());

        UserLikes userLikes = userLikesRepository.findById(userLikesId)
                .orElseThrow(() -> new UserInteractionNotFoundException("UserLikes Not Found"));

        userLikesRepository.delete(userLikes);

        return ApiResponse.success(HttpStatus.OK);
    }

    @Transactional
    public ApiResponse<?> getMyBlackList(InteractionGetRequest interactionGetRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String githubName = authentication.getName();

        int userId = userRepository.findByGithubName(githubName)
                .orElseThrow(() -> new UserNotFoundException(githubName))
                .getId();

        Pageable pageable = PageRequest.of(interactionGetRequest.getPage(), interactionGetRequest.getSize());

        Page<UserBlacklist> userBlacklist = userBlacklistRepository.findByUserId(userId, pageable);

        List<Company> companies = userBlacklist.stream()
                .map(UserBlacklist::getCompany)
                .collect(Collectors.toList());

        CompanyInteractionResponse companyInteractionResponse = CompanyInteractionResponse
                .builder()
                .companies(companies)
                .pagination(new Pagination(userBlacklist.getNumber(), userBlacklist.getSize(), userBlacklist.getTotalPages(), userBlacklist.getTotalElements()))
                .build();

        ApiResponse<?> apiResponse = ApiResponse
                .builder()
                .status(200)
                .code("SU")
                .results(companyInteractionResponse)
                .message("OK")
                .build();

        return apiResponse;
    }

    @Transactional
    public ApiResponse<?> addMyBlackList(InteractionAddRequest interactionAddRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String githubName = authentication.getName();

        User user = userRepository.findByGithubName(githubName).orElseThrow(() -> new UserNotFoundException(githubName));

        Company company = companyRepository.findById(interactionAddRequest.getCompanyId()).orElseThrow(() -> new CompanyNotFoundException("Company not found"));

        UserBlacklistId userBlacklistId = new UserBlacklistId(user.getId(), company.getId());

        if(userBlacklistRepository.existsById(userBlacklistId)) {
            throw new InteractionDuplicateException("Already Exists");

        }

        UserBlacklist userBlacklist = UserBlacklist
                .builder()
                .id(userBlacklistId)
                .user(user)
                .company(company)
                .build();

        userBlacklistRepository.save(userBlacklist);

        return ApiResponse.success(HttpStatus.OK);
    }

    @Transactional
    public ApiResponse<?> deleteMyBlackList(InteractionDeleteRequest interactionDeleteRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String githubName = authentication.getName();

        User user = userRepository.findByGithubName(githubName).orElseThrow(() -> new UserNotFoundException(githubName));

        Company company = companyRepository.findById(interactionDeleteRequest.getCompanyId()).orElseThrow(() -> new CompanyNotFoundException("Company not found"));

        UserBlacklistId userBlacklistId = new UserBlacklistId(user.getId(), company.getId());

        UserBlacklist userBlacklist = userBlacklistRepository.findById(userBlacklistId).orElseThrow(() -> new UserInteractionNotFoundException("UserBlacklist Not Found"));

        userBlacklistRepository.delete(userBlacklist);

        return ApiResponse.success(HttpStatus.OK);
    }
}

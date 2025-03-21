package com.gittowork.domain.user.controller;

import com.gittowork.domain.user.dto.request.InsertProfileRequest;
import com.gittowork.domain.user.dto.request.UpdateInterestsFieldsRequest;
import com.gittowork.domain.user.dto.request.UpdateProfileRequest;
import com.gittowork.domain.user.service.UserService;
import com.gittowork.global.response.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/user")
@AllArgsConstructor(onConstructor = @__(@Autowired))
public class UserController {

    private final UserService userService;

    @PostMapping("/create/profile")
    public ApiResponse<?> insertProfile(@NotNull @Valid InsertProfileRequest insertProfileRequest) {
        return ApiResponse.success(HttpStatus.OK, userService.insertProfile(insertProfileRequest));
    }

    @GetMapping("/select/profile")
    public ApiResponse<?> getMyProfile() {
        return ApiResponse.success(HttpStatus.OK, userService.getMyProfile());
    }

    @PutMapping("/update/profile")
    public ApiResponse<?> updateProfile(@NotNull @Valid UpdateProfileRequest updateProfileRequest) {
        return ApiResponse.success(HttpStatus.OK, userService.updateProfile(updateProfileRequest));
    }

    @GetMapping("/select/interest-field-list")
    public ApiResponse<?> getInterestFields() {
        return ApiResponse.success(HttpStatus.OK, userService.getInterestFields());
    }

    @PutMapping("/update/interest-field")
    public ApiResponse<?> updateInterestField(@NotNull @Valid UpdateInterestsFieldsRequest updateInterestsFieldsRequest) {
        return ApiResponse.success(HttpStatus.OK, userService.updateInterestFields(updateInterestsFieldsRequest));
    }

    @GetMapping("/select/my-interest-field")
    public ApiResponse<?> getMyInterestField() {
        return ApiResponse.success(HttpStatus.OK, userService.myInterestFields());
    }

    @DeleteMapping("/delete/account")
    public ApiResponse<?> deleteAccount() {
        return ApiResponse.success(HttpStatus.OK, userService.deleteAccount());
    }

}

package com.gittowork.domain.user.controller;

import com.gittowork.domain.user.dto.request.InsertProfileRequest;
import com.gittowork.domain.user.dto.request.SelectInterestsFieldRequest;
import com.gittowork.domain.user.dto.request.UpdateInterestsFieldRequest;
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
    public ResponseEntity<?> insertProfile(@NotNull @Valid InsertProfileRequest insertProfileRequest) {
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(HttpStatus.OK, userService.insertProfile(insertProfileRequest)));
    }

    @GetMapping("/select/profile")
    public ResponseEntity<?> getMyProfile() {
        return null;
    }

    @PutMapping("/update/profile")
    public ResponseEntity<?> updateProfile(@NotNull @Valid UpdateProfileRequest updateProfileRequest) {
        return null;
    }

    @GetMapping("/select/interest-field-list")
    public ResponseEntity<?> getInterestField() {
        return null;
    }

    @PostMapping("/create/interest-field")
    public ResponseEntity<?> selectInterestField(@NotNull @Valid SelectInterestsFieldRequest selectInterestsFieldRequest) {
        return null;
    }

    @PutMapping("/update/interest-field")
    public ResponseEntity<?> updateInterestField(@NotNull @Valid UpdateInterestsFieldRequest updateInterestsFieldRequest) {
        return null;
    }

    @GetMapping("/select/my-interest-field")
    public ResponseEntity<?> getMyInterestField() {
        return null;
    }

    @DeleteMapping("/delete/account")
    public ResponseEntity<?> deleteAccount() {
        return null;
    }

}

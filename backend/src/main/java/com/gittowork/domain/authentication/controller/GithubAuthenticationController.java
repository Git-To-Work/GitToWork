package com.gittowork.domain.authentication.controller;

import com.gittowork.domain.authentication.service.GithubAuthenticationService;
import com.gittowork.global.response.ApiResponse;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
@AllArgsConstructor(onConstructor = @__(@Autowired))
public class GithubAuthenticationController {
    private final GithubAuthenticationService githubAuthenticationService;

    @PostMapping("/create/signin")
    public ResponseEntity<?> signInGithub(@NotNull String code) {
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(HttpStatus.OK, githubAuthenticationService.signInGithub(code)));
    }

    @PostMapping("/create/login")
    public ResponseEntity<?> autoLogInGithub() {
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(HttpStatus.OK, githubAuthenticationService.autoLogInGithub()));
    }

    @PostMapping("/create/logout")
    public ResponseEntity<?> logOutGithub() {
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(HttpStatus.OK, githubAuthenticationService.logout()));
    }

}

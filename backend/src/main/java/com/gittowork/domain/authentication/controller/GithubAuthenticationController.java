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
        ApiResponse<Object> response = ApiResponse.builder()
                .status(HttpStatus.OK.value())
                .message(HttpStatus.OK.getReasonPhrase())
                .results(githubAuthenticationService.signInGithub(code))
                .build();
        return ResponseEntity.status(HttpStatus.OK).body(response);
    }

    @PostMapping("/create/login")
    public ResponseEntity<?> autoLogInGithub() {
        ApiResponse<Object> response = ApiResponse.builder()
                .status(HttpStatus.OK.value())
                .message(HttpStatus.OK.getReasonPhrase())
                .results(githubAuthenticationService.autoLogInGithub())
                .build();
        return ResponseEntity.status(HttpStatus.OK).body(response);
    }

    @PostMapping("/create/logout")
    public ResponseEntity<?> logOutGithub() {
        ApiResponse<Object> response = ApiResponse.builder()
                .status(HttpStatus.OK.value())
                .message(HttpStatus.OK.getReasonPhrase())
                .results(githubAuthenticationService.logout())
                .build();
        return ResponseEntity.status(HttpStatus.OK).body(response);
    }

}

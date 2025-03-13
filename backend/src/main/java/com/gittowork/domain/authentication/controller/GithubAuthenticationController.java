package com.gittowork.domain.authentication.controller;

import com.gittowork.domain.authentication.service.GithubAuthenticationService;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
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
    public ResponseEntity<?> signInGithub(String code) {
        return null;
    }
}

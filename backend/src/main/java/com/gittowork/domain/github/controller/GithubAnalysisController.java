package com.gittowork.domain.github.controller;

import com.gittowork.domain.github.dto.request.CreateAnalysisByRepositoryRequest;
import com.gittowork.domain.github.dto.request.SaveSelectedRepositoriesRequest;
import com.gittowork.domain.github.service.GithubService;
import com.gittowork.global.response.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/github")
@AllArgsConstructor(onConstructor = @__(@Autowired))
@Tag(name="Github Analysis")
public class GithubAnalysisController {

    private final GithubService githubService;

    @GetMapping("/select/analysis-by-repository")
    public ApiResponse<?> getGithubAnalysisByRepository(@NotNull @RequestParam int selectedRepositoryId) {
        return ApiResponse.success(githubService.getGithubAnalysisByRepository(selectedRepositoryId));
    }

    @PostMapping("/create/analysis-by-repository")
    public ApiResponse<?> createAnalysisByRepository(@NotNull @RequestBody CreateAnalysisByRepositoryRequest createAnalysisByRepositoryRequest) {
        return ApiResponse.success(HttpStatus.OK, githubService.createGithubAnalysisByRepositoryResponse(createAnalysisByRepositoryRequest.getRepositories()));
    }

    @PostMapping("/create/save-selected-repository")
    public ApiResponse<?> saveSelectedRepositories(@NotNull SaveSelectedRepositoriesRequest saveSelectedRepositoriesRequest) {
        return ApiResponse.success(HttpStatus.OK, githubService.saveSelectedGithubRepository(saveSelectedRepositoriesRequest.getRepositories()));
    }

    @GetMapping("/select/my-repository")
    public ApiResponse<?> myRepository() {
        return ApiResponse.success(HttpStatus.OK, githubService.getMyRepository());
    }

    @GetMapping("/select/my-repository-combination")
    public ApiResponse<?> myRepositoryCombination() {
        return ApiResponse.success(HttpStatus.OK, githubService.getMyRepositoryCombination());
    }

    @DeleteMapping("/delete/my-repository-combination")
    public ApiResponse<?> deleteGithubAnalysisByRepository(@NotNull @RequestParam int selectedRepositoryId) {
        return ApiResponse.success(HttpStatus.OK, githubService.deleteSelectedGithubRepository(selectedRepositoryId));
    }

}

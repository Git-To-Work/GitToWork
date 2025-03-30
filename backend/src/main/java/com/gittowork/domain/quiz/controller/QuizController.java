package com.gittowork.domain.quiz.controller;

import com.gittowork.domain.quiz.service.QuizService;
import com.gittowork.global.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/quiz")
public class QuizController {
    private final QuizService quizService;

    @GetMapping("/{type}")
    public ApiResponse<?> getDeveloperQuiz(@PathVariable String type) {
        return ApiResponse.success(quizService.getDeveloperQuiz(type));
    }

}

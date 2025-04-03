package com.gittowork.domain.fortune.controller;

import com.gittowork.domain.fortune.dto.request.GetTodayFortuneRequest;
import com.gittowork.domain.fortune.dto.request.InsertFortuneInfoRequest;
import com.gittowork.domain.fortune.service.FortuneService;
import com.gittowork.global.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/fortune")
@RequiredArgsConstructor
public class FortuneController {

    private final FortuneService fortuneService;

    @PostMapping("/create/info")
    public ApiResponse<?> insertFortuneInfo(@RequestBody InsertFortuneInfoRequest insertFortuneInfoRequest){
        return ApiResponse.success(HttpStatus.OK, fortuneService.insertFortuneInfo(insertFortuneInfoRequest));
    }

    @GetMapping("/select/info")
    public ApiResponse<?> getFortuneInfo(){
        return ApiResponse.success(HttpStatus.OK, fortuneService.getFortuneInfo());
    }

    @GetMapping("/select/today")
    public ApiResponse<?> getTodayFortune(@RequestBody GetTodayFortuneRequest getTodayFortuneRequest){
        return ApiResponse.success(HttpStatus.OK, fortuneService.getTodayFortune(getTodayFortuneRequest));
    }
}

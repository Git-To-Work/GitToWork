package com.gittowork.global.response;

import lombok.*;
import org.springframework.http.HttpStatus;

@Getter
@Setter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public class ApiResponse<T> {
    private int status;
    private String code;
    private String message;
    private T results;

    public static <T> ApiResponse<T> success(T data) {
        return ApiResponse.<T>builder()
                .status(HttpStatus.OK.value())
                .code(String.valueOf(HttpStatus.OK.value()))
                .message("Success")
                .results(data)
                .build();
    }

    public static <T> ApiResponse<T> success(HttpStatus status) {
        return ApiResponse.<T>builder()
                .status(status.value())
                .code(String.valueOf(status.value()))
                .message("Success")
                .build();
    }

    public static <T> ApiResponse<T> success(HttpStatus status, T data) {
        return ApiResponse.<T>builder()
                .status(status.value())
                .code(String.valueOf(status.value()))
                .message("Success")
                .results(data)
                .build();
    }
}

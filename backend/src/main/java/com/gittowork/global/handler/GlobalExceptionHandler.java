package com.gittowork.global.handler;

import com.gittowork.global.exception.AccessTokenNotFoundException;
import com.gittowork.global.exception.AutoLogInException;
import com.gittowork.global.exception.GithubSignInException;
import com.gittowork.global.exception.UserNotFoundException;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @Getter
    public enum ErrorCode {
        NOT_FOUND("NF","Not found"),
        UNAUTHORIZED("UR", "Unauthorized.");

        private final String code;
        private final String message;

        ErrorCode(String code, String message) {
            this.code = code;
            this.message = message;
        }
    }

    @Setter
    @Getter
    @Builder
    private static class ErrorResponse {
        private final String message;
        private final String code;

        public ErrorResponse(String message, String code) {
            this.message = message;
            this.code = code;
        }

    }

    private ResponseEntity<ErrorResponse> buildErrorResponse(HttpStatus status, String code, String message) {
        ErrorResponse errorResponse = ErrorResponse.builder()
                .message(message)
                .code(code)
                .build();
        return new ResponseEntity<>(errorResponse, status);
    }

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<?> exceptionHandler(UserNotFoundException e) {
        log.warn("User not found: {}", e.getMessage());
        String message = e.getMessage() == null ? ErrorCode.NOT_FOUND.getMessage() : e.getMessage();
        return buildErrorResponse(HttpStatus.NOT_FOUND, ErrorCode.NOT_FOUND.getCode(), message);
    }

    @ExceptionHandler(GithubSignInException.class)
    public ResponseEntity<?> exceptionHandler(GithubSignInException e) {
        log.warn("Github sign in: {}", e.getMessage());
        String message = e.getMessage() == null ? ErrorCode.UNAUTHORIZED.getMessage() : e.getMessage();
        return buildErrorResponse(HttpStatus.UNAUTHORIZED, ErrorCode.UNAUTHORIZED.getCode(), message);
    }

    @ExceptionHandler(AutoLogInException.class)
    public ResponseEntity<?> exceptionHandler(AutoLogInException e) {
        log.warn("Auto log in: {}", e.getMessage());
        String message = e.getMessage() == null ? ErrorCode.UNAUTHORIZED.getMessage() : e.getMessage();
        return buildErrorResponse(HttpStatus.UNAUTHORIZED, ErrorCode.UNAUTHORIZED.getCode(), message);
    }

    @ExceptionHandler(AccessTokenNotFoundException.class)
    public ResponseEntity<?> exceptionHandler(AccessTokenNotFoundException e) {
        log.warn("Access token not found: {}", e.getMessage());
        String message = e.getMessage() == null ? ErrorCode.UNAUTHORIZED.getMessage() : e.getMessage();
        return buildErrorResponse(HttpStatus.UNAUTHORIZED, ErrorCode.UNAUTHORIZED.getCode(), message);
    }
}

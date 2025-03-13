package com.gittowork.global.exception;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserNotFoundException extends RuntimeException {
    private final int status;
    private final int code;

    public UserNotFoundException(int status, int code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }
}

package com.gittowork.domain.firebase.service;

import com.gittowork.domain.firebase.dto.request.GetTokenRequest;
import com.gittowork.domain.firebase.entity.UserAlertLog;
import com.gittowork.domain.firebase.repository.UserAlertLogRepository;
import com.gittowork.domain.user.entity.User;
import com.gittowork.domain.user.repository.UserRepository;
import com.gittowork.global.exception.UserNotFoundException;
import com.gittowork.global.response.MessageOnlyResponse;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class FirebaseService {

    private final UserAlertLogRepository userAlertLogRepository;
    private final UserRepository userRepository;

    @Transactional
    public MessageOnlyResponse insertFcmToken(GetTokenRequest getTokenRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String userName = authentication.getName();

        User user = userRepository.findByGithubName(userName)
                .orElseThrow(() -> new UserNotFoundException(userName));

        user.setFcmToken(getTokenRequest.getFcmToken());

        userRepository.save(user);

        return MessageOnlyResponse.builder()
                .message("FCM 토큰이 성공적으로 저장되었습니다.")
                .build();
    }

    @Transactional
    public void sendMessage(User user, String title, String message, String alertType) throws FirebaseMessagingException {
        String firebaseMessage = FirebaseMessaging.getInstance().send(
                Message.builder()
                        .setNotification(
                                Notification.builder()
                                        .setTitle(title)
                                        .setBody(message)
                                        .build())
                        .setToken(user.getFcmToken())
                        .build());

        userAlertLogRepository.save(
                UserAlertLog.builder()
                        .alertType(alertType)
                        .user(user)
                        .title(title)
                        .message(message)
                        .createDttm(LocalDateTime.now())
                        .build()
        );

        log.info("Firebase send message: {}", firebaseMessage);
    }

}

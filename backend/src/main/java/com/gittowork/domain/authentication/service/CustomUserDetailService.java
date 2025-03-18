package com.gittowork.domain.authentication.service;

import com.gittowork.domain.authentication.entity.CustomUserDetails;
import com.gittowork.domain.user.entity.User;
import com.gittowork.domain.user.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

/**
 * CustomUserDetailsService
 * 1. 메서드 설명: 주어진 username(여기서는 GitHub 로그인명)을 기반으로 사용자 엔티티를 조회하여 UserDetails 객체를 생성한다.
 * 2. 로직:
 *    - findByGithubName(username)을 호출하여 User 엔티티를 조회한다.
 *    - 조회된 User를 CustomUserDetails로 래핑하여 반환한다.
 *    - 사용자가 없으면 UsernameNotFoundException 예외를 발생시킨다.
 * 3. param: username (GitHub 로그인명)
 * 4. return: CustomUserDetails 객체
 */
@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Autowired
    public CustomUserDetailsService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByGithubName(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with username: " + username));
        return new CustomUserDetails(user);
    }
}
package com.gittowork.domain.authentication.entity;

import com.gittowork.domain.user.entity.User;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;

/**
 * CustomUserDetails
 * 1. 메서드 설명: 사용자 엔티티(User)의 정보를 Spring Security의 UserDetails 인터페이스에 맞게 래핑한다.
 * 2. 로직:
 *    - getUsername(): 사용자의 GitHub 로그인명(githubName)을 반환
 *    - getAuthorities(): 사용자 권한 목록을 반환 (여기서는 기본적으로 ROLE_USER를 부여)
 *    - 나머지 메서드(isAccountNonExpired, isAccountNonLocked, isCredentialsNonExpired, isEnabled)는 모두 true 반환
 * 3. param: User 엔티티
 * 4. return: UserDetails 객체
 */
public class CustomUserDetails implements UserDetails {

    private final User user;

    public CustomUserDetails(User user) {
        this.user = user;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER"));
    }

    @Override
    public String getPassword() {
        return null;
    }

    @Override
    public String getUsername() {
        return user.getGithubName();
    }


}
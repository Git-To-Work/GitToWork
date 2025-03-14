package com.gittowork.global.utils;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;

import java.security.Key;
import java.util.Date;

public class JwtUtil {
    private final static Key JWT_SECRET = Keys.secretKeyFor(SignatureAlgorithm.HS256);
    private final static long EXPIRATION_TIME = 1000 * 60 * 60 *24 * 366;// 366일

    public static String generateToken(String username) {
        return Jwts.builder()
                .setSubject(username)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis()+EXPIRATION_TIME))
                .signWith(JWT_SECRET, SignatureAlgorithm.HS256)
                .compact();
    }

    public String validateToken(String token) {
        try {
            Claims claims = Jwts.parserBuilder()
                    .setSigningKey(JWT_SECRET)
                    .build()
                    .parseClaimsJws(token)
                    .getBody();

            return claims.getSubject();

        }catch (ExpiredJwtException e) {
            System.out.println("JWT 토큰이 만료되었습니다: " + e.getMessage());
        } catch (UnsupportedJwtException e) {
            System.out.println("지원되지 않는 JWT 형식입니다: " + e.getMessage());
        } catch (MalformedJwtException e) {
            System.out.println("잘못된 JWT 서명입니다: " + e.getMessage());
        } catch (SecurityException e) {
            System.out.println("JWT 서명 검증 실패: " + e.getMessage());
        } catch (IllegalArgumentException e) {
            System.out.println("JWT 토큰이 비어있거나 잘못되었습니다: " + e.getMessage());
        }
        return null;
    }

    public boolean isTokenExpired(String token) {
        try {
            Date expiration = Jwts.parserBuilder()
                    .setSigningKey(JWT_SECRET)
                    .build()
                    .parseClaimsJws(token)
                    .getBody()
                    .getExpiration();

            return expiration.before(new Date());

        } catch (ExpiredJwtException e) {
            return true;
        }
    }
}

package com.gittowork.global.utils;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;

@Component
public class JwtUtil {

    private static final Logger logger = LoggerFactory.getLogger(JwtUtil.class);

    private final static Key JWT_SECRET = Keys.secretKeyFor(SignatureAlgorithm.HS256); //SECRET_KEY 환경변수에서 가져오는 걸로 바꿔야함.

    private final static long ACCESS_EXPIRATION_TIME = 1000L * 60 * 60;// 1시간
    private final static long REFRESH_EXPIRATION_TIME = 1000L * 60 * 60 * 24 * 366;// 366일

    public static String generateAccessToken(String username) {
        return Jwts.builder()
                .setSubject(username)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis()+ACCESS_EXPIRATION_TIME))
                .signWith(JWT_SECRET, SignatureAlgorithm.HS256)
                .compact();
    }

    public String generateRefreshToken(String username) {
        return Jwts.builder()
                .setSubject(username)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + REFRESH_EXPIRATION_TIME))
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
            logger.warn("JWT 토큰이 만료되었습니다: {}", e.getMessage());
        } catch (UnsupportedJwtException e) {
            logger.warn("지원되지 않는 JWT 형식입니다: {} ", e.getMessage());
        } catch (MalformedJwtException e) {
            logger.warn("잘못된 JWT 서명입니다: {}", e.getMessage());
        } catch (SecurityException e) {
            logger.warn("JWT 서명 검증 실패: {}", e.getMessage());
        } catch (IllegalArgumentException e) {
            logger.warn("JWT 토큰이 비어있거나 잘못되었습니다: {}", e.getMessage());
        }
        return null;
    }

    public boolean isValidToken(String token) {
        try {
            Jwts.parserBuilder()
                    .setSigningKey(JWT_SECRET)
                    .build()
                    .parseClaimsJws(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            logger.warn("JWT 검증 실패: {}", e.getMessage());
            return false;
        }
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
        } catch(Exception e){
            logger.error("토큰 만료 여부 확인 중 오류 발생: {}", e.getMessage());
            return true;
        }
    }

    public long getRemainExpiredTime(String token){
        try {
            Claims claims = Jwts.parserBuilder()
                    .setSigningKey(JWT_SECRET)
                    .build()
                    .parseClaimsJws(token)
                    .getBody();

            long expirationTime = claims.getExpiration().getTime();
            long currentTime = System.currentTimeMillis();

            long remainingTime = expirationTime - currentTime;
            return Math.max(remainingTime, 0);

        } catch (ExpiredJwtException e) {
            return 0;
        } catch (Exception e) {
            logger.error("남은 만료 시간 계산 실패: {}", e.getMessage());
            return -1;
        }
    }

    public String getUsername(String token) {
        try{
            Claims claims = Jwts.parserBuilder()
                    .setSigningKey(JWT_SECRET)
                    .build()
                    .parseClaimsJws(token)
                    .getBody();

            return claims.getSubject();

        }catch (Exception e){
            logger.error("사용자를 가져올 수 없습니다: {}", e.getMessage());
            return null;
        }
    }
}

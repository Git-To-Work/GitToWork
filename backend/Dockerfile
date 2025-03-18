# 1단계: Gradle 빌드 단계 (JDK 17 환경)
FROM gradle:7.6.0-jdk17 AS builder
WORKDIR /home/app
# 프로젝트 소스 전체 복사
COPY . .
# Gradle 빌드 실행 (빌드 산출물은 build/libs 아래에 생성됨)
RUN chmod +x gradlew && ./gradlew clean build --no-daemon --refresh-dependencies

# 2단계: 실행 단계 (Liberica JDK 17 사용)
FROM bellsoft/liberica-openjdk-alpine:17
WORKDIR /app
# 빌드 단계에서 생성된 jar 파일 복사 (파일명이 여러 개일 경우 필요에 따라 조정)
COPY --from=builder /home/app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]


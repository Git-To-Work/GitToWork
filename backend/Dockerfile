# 1단계: Gradle 빌드 단계 (JDK 17 환경)
FROM gradle:7.6.0-jdk17 AS builder
WORKDIR /home/app
# 프로젝트 소스 전체 복사
COPY . .
# Gradle 빌드 실행 (빌드 산출물은 build/libs 아래에 생성됨)
RUN chmod +x gradlew && ./gradlew clean build --no-daemon --refresh-dependencies

# 2단계: 실행 단계 (Liberica JDK 17 사용, Alpine 기반)
FROM bellsoft/liberica-openjdk-alpine:17
WORKDIR /app

# /tmp/repositories 디렉토리 미리 생성 및 권한 설정
RUN mkdir -p /tmp/repositories && chmod -R 777 /tmp/repositories

# 필요한 패키지 설치 (curl, unzip, bash 등)
RUN apk add --no-cache curl unzip bash

# sonar-scanner 설치 및 압축 해제
RUN curl -Lo sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip && \
    unzip sonar-scanner.zip && \
    mv sonar-scanner-4.8.0.2856-linux /opt/sonar-scanner && \
    rm sonar-scanner.zip

# PATH 에 sonar-scanner 실행 파일이 포함된 디렉토리 추가
ENV PATH=$PATH:/opt/sonar-scanner/bin

# 빌드 단계에서 생성된 jar 파일 복사 (파일명이 여러 개일 경우 필요에 따라 조정)
COPY --from=builder /home/app/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]


# Ubuntu 기반 이미지 사용 (원하는 버전에 따라 변경 가능)
FROM ubuntu:22.04

# 기본 패키지 업데이트 및 필수 도구 설치
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    xz-utils

# Flutter 3.29.2 설치 (Flutter 공식 스토리지에서 해당 버전 tar.xz 파일 다운로드)
WORKDIR /tmp
RUN curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.2-stable.tar.xz && \
    tar xf flutter_linux_3.29.2-stable.tar.xz && \
    mkdir -p /sdks && mv flutter /sdks/flutter

# 환경 변수 설정: Flutter SDK 경로를 PATH에 추가
ENV PATH="/sdks/flutter/bin:${PATH}"
ENV FLUTTER_HOME="/sdks/flutter"

# Flutter 설치 확인 (필요한 경우 flutter doctor 실행)
RUN flutter doctor

# 권한 수정: 컨테이너 내부에서 jenkins 사용자가 사용한다고 가정할 경우 (jenkins UID: 1000)
USER root
RUN chown -R 1000:1000 /sdks/flutter
# Jenkins 사용자로 전환 (컨테이너 내에 jenkins 사용자가 존재해야 합니다)
USER 1000

# 기본 커맨드 (원하는대로 CMD 설정)
CMD ["flutter", "--version"]

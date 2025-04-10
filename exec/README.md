# Infra

version:
Docker version 27.5.1
mysql : 8.0.22
mongo: 8.0.4
redis : 7
nginx : latest

주요 계정 및 프로퍼티 정의 된 파일 링크 : [Notion 링크](https://diamond-armadillo-65d.notion.site/1b42435c61c9806096c7f19723501036?pvs=74)

# Backend

version:

JVM17

JDK17 : Liberica JDK 17.0.14<br>
springboot : 3.4.3<br>
gradle : 7.6.0<br>
intellij : 2023.3.1<br>
sonarqube : 25.4.0.105899<br>
openai : gpt-4<br>

```sh
git clone https://lab.ssafy.com/s12-bigdata-recom-sub1/S12P21C103.git
```

/backend/src/main/resources에 백엔드 application.properties 복사<br>
/backend/src/main/resources에 백엔드 gittowork-firebase-key.json 복사<br>
/backend/src/main/resources에 백엔드 application.yml 복사<br>

```sh
docker-compose up
```


# Frontend

Flutter : 3.29.2<br>
Dart : 3.7.2<br>
Android studio : 2024.2.2<br>
Emulator : Galaxy S25+ [설치링크](https://developer.samsung.com/galaxy-emulator-skin)


/frontend/gittowork 경로에 프론트엔드를 복사해서 .env로 이름 변경

#### APK 설치
```sh
flutter build apk --release
```
#### Emulator 실행
```sh
Android-Studio Emulator 실행
```


# Python:

python:3.11


## BigData Model:

/bigdata 경로에 파이썬 백엔드를 복사해서 .env로 이름 변경

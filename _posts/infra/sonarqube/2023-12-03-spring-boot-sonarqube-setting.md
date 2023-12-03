---
layout: post
title: Spring boot + jacoco + sonarqube 설정
date: 2023-12-03 13:24
description: Spring boot에 jacoco 커버리지 도구와, sonarqube 설정을 진행하는 방법에 대해 알아본다.
comments: true
categories: [Infra, SonarQube]
tags: [Infra, Jacoco, SonarQube, Spring boot, Setting]
---

## 시작하며...

Spring boot 프로젝트에 jacoco와 sonarqube를 설정하는 방법에 대해 알아보겠습니다.

## 포스팅의 주요 내용

이번 포스팅에서는 다음과 같은 내용을 다룹니다:

1. jacoco와 sonarqube에 대한 상세한 소개
2. Spring boot에 jacoco와 sonarqube를 설정하는 방법

## 각 도구에 대해
### jacoco란?

jacoco는 자바 코드의 테스트 커버리지를 측정하는 도구입니다. 이를 통해 코드의 테스트가 얼마나 충분히 이루어졌는지를 확인할 수 있습니다. 또한, jacoco는 높은 수준의 코드 커버리지를 제공하며, 코드의 품질을 향상시키는 데 도움이 됩니다.

### SonarQube란?

SonarQube는 코드 품질을 관리하고 향상시키는 데 도움이 되는 오픈 소스 플랫폼입니다. 코드의 복잡성, 중복성, 테스트 커버리지, 코딩 표준 준수 여부 등을 체크할 수 있습니다. 또한, SonarQube는 코드의 품질을 지속적으로 추적하고 개선할 수 있는 기능을 제공합니다.

## Spring boot 설정 방법

Spring boot 프로젝트에 jacoco와 sonarqube를 설정하는 방법은 다음과 같습니다:

### 1. jacoco 설정
1. `build.gradle` 파일 설정

```gradle
// ...

plugins {
    // ...

    // jacoco
    id 'jacoco'
}

// ...

jacoco {
    toolVersion = "0.8.10"
}

// ...

tasks.named('test') {
    useJUnitPlatform()

    // 테스트 후 Jacoco 리포트 실행
    finalizedBy(tasks.jacocoTestReport)
}

jacocoTestReport {
    reports {
        xml.required = true
        html.required = true
        csv.required = false

        xml.destination file("${buildDir}/jacoco/jacoco.xml")
        html.destination file("${buildDir}/jacoco/jacocoHtml")
    }

    // 클래스 제외 처리를 위한 필터
    afterEvaluate {
        classDirectories.setFrom(
                files(classDirectories.files.collect {
                    fileTree(dir: it, excludes: [
                            "**/*Application*",
                            "**/entity/Q*"
                    ])
                })
        )
    }
}
```

위 설정 후 `./gradlew test`를 실행하면, `build/jacoco` 디렉토리에 `jacoco.xml` 파일과 `jacocoHtml` 디렉토리내에 HTML 리포트가 생성된다.

> 현재는 테스트 코드가 제대로 작성되어 있지 않으므로, 코드 커버리지 기준(통과율 설정 등)은 설정에서 제외 합니다.

### 2. sonarqube 설정

> 사내 `SonarQube` 서비스는 `docker-compose`를 이용하여 설정되어 있다. 서버 설정 방법은 별도 포스팅을 이용하여 설명 한다.

1. `SonarQube` 토큰 발급

![SonarQube 토큰 발급](/assets/img/post/infra/sonarqube/spring-boot-sonarqube-setting/001.png)
   1. 화면 우측 상단의 아이콘을 클릭하여 사용 팝업 메뉴를 표시한다.
   2. 사용자 팝어 메뉴에서 `My Account` 메뉴를 클릭한다.
   3. 상단 탭 메뉴에서 `Security`를 선택한다.
   4. 토큰 구분을 위한 토큰 이름을 입력한다. 이름을 입력하면 `Generate` 버튼이 활성화 된다. 
      - Type: 선택 할 수 있는 타입이 3개가 표시되는데, 나의 경우 전역으로 사용 할 토큰이므로 `Global Analysis Token`을 선택 하였다.
      - 만료일(`Expires in`)은 나의 경우 1년으로 설정 하였다. 상황에 맞게 적당히 선택한다. 만료일 없도록 설정 한는 것도 가능 한 듯 하다.
   5. `Generate` 버튼을 클릭하면 토큰이 발급 된다. 발급 된 토큰은 뒤에 설정 하는데 사용해야 하므로 잘 복사해 둔다.

2. `build.gradle` 파일 설정

```gradle
// ...

plugins {
    // ...

    // SonarQube
    id "org.sonarqube" version "4.4.1.3373"
}

// ...

// sonarqube
sonarqube {
    properties {
        property "sonar.host.url", "https://{{ SONARQUBE_DOMAIN }}"
        property "sonar.token", "{{ SONARQUBE_TOKEN }}"
        property "sonar.projectKey", "{{ PROJECT_UNIQUE_KEY }}"
        property "sonar.projectName", "{{ PROJECT_NAME }}-${version}"
        property "sonar.sources", "src/main"
        property "sonar.language", "java"
        property "sonar.sourceEncoding", "UTF-8"
        property "sonar.profile", "Sonar way"
        property "sonar.java.binaries", "${buildDir}/classes/java/main"
        property "sonar.test.inclusions", "**/*Tests.java"
        property "sonar.exclusions", "**/entity/Q*, **/*Application*, **/*Tests*"
        property "sonar.coverage.jacoco.xmlReportPaths", "${buildDir}/jacoco/jacoco.xml"
    }
}
```

   - `{{ SONARQUBE_DOMAIN }}`: 미리 설치된 SonarQube URL을 입력한다.
   - `{{ SONARQUBE_TOKEN }}`: 위 1번에서 발급한 SonarQube Token을 입력한다.
   - `{{ PROJECT_UNIQUE_KEY }}`: 프로젝트 고유 값을 입력한다. 정적분석 이력 관리등에 프로젝트를 관리하는데 사용한다.
   - `{{ PROJECT_NAME }}`: 나의 경우 프로젝트 고유값에 `build.gradle`에 설정된 버전을 suffix로 사용하여 프로젝트 명을 설정한다. SonarQube 화면에 표시되는 프로젝트 명이고, 버전별로 분석 결과 추이를 파악하는데 도움이 된다.
   - 위에 설정 한 `Jacoco`의 `xml`보고서 경로 등 필요한 설정을 위 내용을 참고하여 추가해 준다.

3. `SonarQube` 분석 실행.

```shell
$ ./gradlew test sonar
```

위와 같이 실행하면, 테스트 코드 실행 -> Jacoco 보고서 작성 -> SonarQube 분석 및 보고서 전송 이 진행 된다.


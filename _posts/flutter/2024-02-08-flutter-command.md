---
layout: post
title: Flutter 명령어 정리
date: 2024-02-17 09:20:00 +0900
description: Flutter 명령어를 정리한다.
comments: true
categories: [ Flutter ]
tags: [ Flutter, Command ]
---

_Flutter 종속성 설정 추가(라이브러리 설치)_
```bash
flutter pub add table_calendar
```

_Dart 소스코드 포멧_
현재 디렉토리 및 하위 디렉토리의 dart파일의 형식 지정.
```bash
dart format .
```

소스코드를 변경하지 않고 형식의 차이만 확인하려면, `-o show` 옵션을 사용한다.
```bash
dart format -o show .
```

---
layout: post
title: AWS EC2 인스턴스 시작 후 초기화 작업
date: 2024-01-20 14:09:43 +0900
description: AWS EC2 인스턴스 시작 후 초기 작업 명령을 정리 한다.
comments: true
categories: [ Infra, AWS ]
tags: [ AWS, EC2, Setup, Command ]
---

## EC2 인스턴스 시작 후 초기화 작업
Ubuntu 22.04 LTS의 m2.micro 인스턴스와, m2.large 인스턴스를 생성하였다.
각각 m2.micro 인스턴스는 웹서버로 nginx를 설치하여 구성하고, m2.large 인스턴스는 Docker를 설치하여 서비스를 설치하도록 구성하였다.
이 2개 인스턴스를 생성하고, 초기 설정한 내용을 기록한다.

### 1. hostname 변경
기본 설정된 hostname 은 `ip-###-###-###-###` 형태로 되어 있어서, 여러 인스턴스간 작업시 혼란을 줄 수 있으므로 변경한다.
```bash
sudo hostnamectl set-hostname <hostname>
```
명령 실행 후, 재접속 하면 명령 프롬프트의 hostname 이 변경된 것을 확인 할 수 있다.

> 이후 각 서비스별 설정을 진행 한다. 공통 설정이 필요한 경우 이어서 포스팅을 진행한다.

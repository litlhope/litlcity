---
layout: post
title: nginx 서버에 대용량 파일 업로드 설정
date: 2023-09-08 18:08
description: nginx 서버에 대용량 파일 업로드 설정 방법을 기술한다.
comments: true
categories: [ Infra, Nginx ]
tags: [ Nginx, Setting ]
---

## 상황
`Nexus3`설정 후 저장소에 도커 이미지 Push 처리시에 413오류(Request Entity Too Large)가 발생하였다.

## 해결
`Nginx`는 기본적으로 1MB이상의 파일 업로드를 허용하지 않는다. 이를 해결 하기 위해, 저장소용 도메인 `repo.bud-it.com`의 `server` 설정에
다음 내용을 추가하였다.

***repo.bud-it.com.conf***
```nginx
server {
  listen 80;
  listen [::]:80;

  server_name repo.bud-it.com;
  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl;
  server_name repo.bud-it.com;

  ...

  # Docker 이미지 등 용량이 큰 파일 업로드를 위한 설정 추가
  client_max_body_size 4G;

  ...
}
```

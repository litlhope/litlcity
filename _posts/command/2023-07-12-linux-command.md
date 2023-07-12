---
layout: post
title: Linux(Ubuntu) 명령어
date: 2023-07-12 09:45
description: Linux를 사용하면서 자주 검색하거나, 잡다한 명령어 정리
comments: true
categories: [Command]
tags: [Command, Linux, Ubuntu, CLI]
---

## 시작하며...
Linux(주로 Ubuntu)를 사용하면서 자주 검색하게 되거나, 별도 토픽으로 작성하기에는 부족한 잡다한 명령어들을 정리하고자한다.
이곳에 정리하다. 토픽 내용이 많아지면 별도 토픽으로 분리할 예정이다.

## 명령어 모음

### `nginx`
```shell
# nginx 버전 확인
$ nginx -v
nginx version: nginx/1.18.0 (Ubuntu)

# nginx 설정 문서 Syntax 확인
$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

# nginx 시작[종료/재시작/상태확인]
$ sudo service nginx start[stop/restart/status]
```

### 리눅스 버전 확인
```shell
$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.2 LTS
Release:	22.04
Codename:	jammy
```

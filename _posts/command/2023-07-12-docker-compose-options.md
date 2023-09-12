---
layout: post
title: docker-compose 옵션 설명
date: 2023-07-12 09:30
description: docker-compose를 사용하면서 알게 된 옵션들을 정리한다.
comments: true
categories: [Command]
tags: [Command, docker-compose]
---

## 시작하며...
`docker-compose`를 사용하면서 알게 된 옵션들을 정리한다.

## 명령어 옵션
### 1. `--env-file`
`docker-compose.yml` 파일에서 사용 할 환경변수 파일을 지정한다.
예를 들어 `.docker/local.env` 환경변수 파일을 이용하는 샘플은 다음과 같다.

***.docker/local.env***
```dotenv
SERVICE_PORT=8081:8080
```

***docker-compose.yml***
```yaml
version: '3.8'
services:
  service:
    image: service:latest
    ports:
      - ${SERVICE_PORT}
```

***docker-compose 명령어***
```bash
$ docker-compose --env-file=./.docker/local.env up -d
```
> 참고:
> `docker-compose.yml`파일과 같은 경로에 `.env` 파일이 있으면 자동으로 환경변수 파일로 인식한다.


## `yaml` 파일 옵션

### 1. `restart`
1. `no` : 컨테이너가 종료되면 다시 시작하지 않는다.
2. `always` : 컨테이너가 종료되면 항상 다시 시작한다.
3. `on-failure` : 컨테이너가 종료되면 `exit code`가 0이 아닌 경우에만 다시 시작한다.
4. `unless-stopped` : 컨테이너가 종료되면 항상 다시 시작한다. `docker-compose down` 명령어로 종료해도 다시 시작한다.
   * 정확한 내용 확인 필요

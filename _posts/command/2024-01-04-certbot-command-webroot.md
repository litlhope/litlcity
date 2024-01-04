---
layout: post
title: certbot (웹 루트) 명령어를 이용한 인증서 발급/갱신
date: 2024-01-04 14:32
description: certbot 웹 루트 명령어 사용 방법에 대해서 정리 한다.
comments: true
categories: [Command]
tags: [CLI, Command, certbot]
---

## 시작하며...
사내 SSL 인증서 관리를 위해 certbot을 사용하고 있다.
그동안은 `--standalone` 옵션을 사용하여 인증서를 발급 받고 갱신해 왔다. 이 방법은 웹서버를 잠시 정지해야 하는 문제가 있었다.
개발이 진행중인 동안에는 문제가 없었으나, 서비스를 위해 운영서버를 구축하고, 인증서 발급을 위해 서비스가 중단되어서는 안되기 때문에, `--webroot`를 사용하는 형태로
인증서 발급 및 갱신 방법을 변경하였다. 이에 대한 설명을 정리 하고자 한다.
이전 `--standalone`을 이용하는 방법에 대한 설명은 [여기]({% post_url 2023-07-10-certbot-command %})를 참고하자.

### `certbot`이란?
`certbot`은 [Let's Encrypt](https://letsencrypt.org)의 SSL 인증서 사용을 관리하는 무료 오픈소스 도구이다.
`certbot` 명령을 이용하여, 무료로 사용 할 수 있는 SSL 인증서를 발급/갱신/삭제 관리 할 수 있다.
무료로 발급받은 인증서는 유효기간 3개월(90일)의 제약을 갖으므로, `certbot`을 이용하여 주기적으로 갱신해야 한다.

## 환경
```shell
$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.2 LTS
Release:	22.04
Codename:	jammy

$ certbot --version
certbot 2.8.0
```

## 명령어
`your.domain.com`이라는 도메인에 대해 인증서 발급을 위한 준비 및 실행 명령어에 대해 설명 한다.

### 0. 준비
#### 1. nginx 설정
인증서 발급을 위해 Let's Encrypt에서 도메인 검증을 위해 80포트로 접속을 시도합니다. 이에 대한 설정이 되어 있어야 한다.
`/etc/nginx/site-available/your.domain.com.conf` 파일을 생성하고, 아래와 같이 설정을 추가한다.
```nginx
server {
    # 인증서 발급을 위한 설정
    listen 80;
    listen [::]:80;

    server_name your.domain.com;

    root /var/www/html;
    index index.html index.nginx-debian.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```
> `your.domain.com` 부분은 실제 자신의 도메인으로 변경하여 설정한다.

`/etc/nginx/site-enabled/your.domain.com.conf`으로 심볼릭 링크를 걸어준다.
```bash
$ cd /etc/nginx/site-enabled
$ sudo ln -s ../site-available/your.domain.com.conf your.domain.com.conf
```

#### 2. `index.html` 생성
동일한 도메인의 `https:` 프로토콜을 사용하여 redirect 처리하도록 `/var/www/html` 경로에 아래 내용을 참고하여 `index.html` 파일을 추가해 준다.
```html
<!DOCTYPE html>
<html>
<head>
<title>BUD-IT Branch Page</title>
</head>
<body>
    <script type="text/javascript">
        if (location.protocol !== 'https:') {
            location.replace(`https:${location.href.substring(location.protocol.length)}`);
        }
    </script>
</body>
</html>
```

#### 3. nginx 재시작
nginx 설정에 문법 오류가 없는지 체크 후 nginx를 재시작한다.
```bash
$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

$ sudo service nginx restart
```

### 1. 인증서 발급
```shell
$ sudo certbot certonly \
  --webroot \
  --agree-tos \
  -m ligno@bud-it.com \
  -w /var/www/html \
  -d your.domain.com \
  --cert-name domain-name
```
* 인증서를 사용 할 서버에서 명령어를 실행해야한다.
* `-m ligno@bud-it.com` : 인증서 관리자 메일 주소를 입력한다. 인증서 발급 후 인증메일이 수신된다.
* `-w /var/www/html` : 웹 페이지 루트 경로를 입력해 준다.
* `-d your.domain.com` : 인증서를 발급 받을 도메인 주소를 입력해 준다.
* `--cert-name domain-name` : 관리 용도의 인증서 이름을 입력해 준다. 생략 할 수 있고, 생략 할 경우 도메인을 사용한다.

### 2. 인증서 갱신
```shell
$ sudo certbot certonly \
  --force-renew \
  --webroot \
  -w /var/www/html \
  -m ligno@bud-it.com \
  -d your.domain.com
```

> 그 외 인증서 목록 확인, 인증서 삭제 등은 [이전 게시글]({% post_url 2023-07-10-certbot-command %})을 참고한다.

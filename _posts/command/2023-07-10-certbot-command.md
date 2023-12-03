---
layout: post
title: certbot 명령어
date: 2023-07-10 11:42
description: certbot 명령어 사용 방법에 대해서 정리 한다.
comments: true
categories: [Command]
tags: [CLI, Command, certbot]
---

## 시작하며...
사내 SSL 인증서 관리를 위해 certbot을 사용하고 있다.

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
certbot 2.6.0
```

## 명령어
### 1. 인증서 발급
```shell
$ sudo certbot certonly --cert-name certname --standalone --agree-tos -d yourdomain.com
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Requesting a certificate for yourdomain.com

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/certname/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/certname/privkey.pem
This certificate expires on 2023-10-08.
These files will be updated when the certificate renews.
Certbot has set up a scheduled task to automatically renew this certificate in the background.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```
* 인증서를 사용 할 서버에서 명령어를 실행해야한다.
* `certname`은 발급받을 인증서의 이름이다.
* `yourdomain.com`은 인증서를 발급받을 도메인이다.
* `--standalone` 옵션은 `certbot`이 자체적으로 웹서버를 구동하여 인증서 발급을 진행한다.
   * `certbot`이 80 포트를 사용하기 때문에, 웹서버가 80 포트를 사용하고 있으면 인증서 발급이 불가능하다.
* `--agree-tos` 옵션은 `certbot`이 사용자에게 동의를 묻지 않고 진행한다.

#### 발생 할 수 있는 문제
1. 웹서버가 80 포트를 점유

   ```shell
   $ sudo certbot certonly --cert-name nexus3 --standalone --agree-tos -d nexus3.bud-it.com
   Saving debug log to /var/log/letsencrypt/letsencrypt.log
   Requesting a certificate for nexus3.bud-it.com
   
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Could not bind TCP port 80 because it is already in use by another process on
   this system (such as a web server). Please stop the program in question and then
   try again.
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   (R)etry/(C)ancel:
   ```
   - 해결 방법
      - `c` 입력하여 발급 취소
      - 웹서버를 중지
        ```shell
        $ sudo service nginx stop
        ```
      - `certbot` 명령어 실행
      - 웹서버 재시작
        ```shell
        $ sudo service nginx start
        ```

### 2. 발급된 인증서 목록 조회
```shell
$ sudo certbot certificates
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Found the following certs:
  Certificate Name: mycert
    Serial Number: x4x3edxx81xxx00bxx2xa3xxxfxxexxdxxx
    Key Type: RSA
    Domains: exam.mycert.ce
    Expiry Date: 2024-01-02 18:21:45+00:00 (VALID: 30 days)
    Certificate Path: /etc/letsencrypt/live/mycert/fullchain.pem
    Private Key Path: /etc/letsencrypt/live/mycert/privkey.pem

  ...

    Certificate Path: /etc/letsencrypt/live/zabbix/fullchain.pem
    Private Key Path: /etc/letsencrypt/live/zabbix/privkey.pem
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

### 3. 인증서 갱신
```shell
$ sudo certbot certonly --force-renew --standalone -d yourdomain.com
Saving debug log to /var/log/letsencrypt/letsencrypt.log
...
```
신규 인증서 발급과 마찬가지로, 80 포트를 이용하여 검증용 웹 서버를 띄워서 인증서를 발급 하므로, 잠시 80포트를 사용 중인 웹 서비스를 중지 후 처리해야 한다.

### 4. 인증서 삭제
인증서 삭제는 인자를 주고, 원하는 인증서를 바로 삭제 할 수도 있고, 아래와 같이 대화형으로 삭제 할 수 있다.
```shell
$ sudo certbot delete
Saving debug log to /var/log/letsencrypt/letsencrypt.log

Which certificate(s) would you like to delete?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
1: mycert

...

20: zabbix
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Select the appropriate numbers separated by commas and/or spaces, or leave input
blank to select all options shown (Enter 'c' to cancel): c
User ended interaction.
Ask for help or search for solutions at https://community.letsencrypt.org. See the logfile /var/log/letsencrypt/letsencrypt.log or re-run Certbot with -v for more details.
```
위 예에서는 `c`(`cancel`)을 입력하여 삭제를 취소 하였지만, 삭제 할 인증서 이름 앞의 숫자를 입력하여 삭제를 진행 할 수 있다.

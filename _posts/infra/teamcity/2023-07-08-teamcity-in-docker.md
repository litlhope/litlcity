---
layout: post
title: TeamCity 설치 - docker-compose
date: 2023-07-08 12:06
description: docker-compose 설정으로 Teamcity를 설치하는 방법에 대해 기술 한다.
comments: true
categories: [Infra, TeamCity]
tags: [TeamCity, Docker, Infra, Setting]
---

## 시작하며...
Ubuntu에서 `Docker` 이미지의 `TeamCity`를 설치하는 방법에 대해 알아본다.

## 작업환경
```shell
# OS Version
$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.2 LTS
Release:	22.04
Codename:	jammy

# Docker Version
$ docker --version
Docker version 24.0.2, build cb74dfc

# docker-compose Version
$ docker-compose --version
docker-compose version 1.29.2, build unknown

# nginx Version
$ nginx -v
nginx version: nginx/1.18.0 (Ubuntu)
```

## TeamCity 설치

### 설정파일 작성
#### 1. 환경 변수용 `.env`파일 추가
> 각 설정 값은 본인의 환경에 맞게 수정한다.
 
***.env***
```dotenv
TEAMCITY_VERSION=2023.05
TEAMCITY_EXT_PORT=xxxx

MYSQL_DB_NAME=db_name
MYSQL_ROOT_PW=db_root_password
MYSQL_ROOT_HOST=host_ip
MYSQL_USER=db_user
MYSQL_PW=db_user_password
MYSQL_EXT_PORT=xxxx
```
* `TEAMCITY_VERSION` : TeamCity 버전
* `TEAMCITY_EXT_PORT` : TeamCity 접속용 포트
* `MYSQL_DB_NAME` : TeamCity DB 이름
* `MYSQL_ROOT_PW` : TeamCity DB root 계정 비밀번호
* `MYSQL_ROOT_HOST` : TeamCity DB root 계정 접속 허용 호스트
* `MYSQL_USER` : TeamCity DB 계정
* `MYSQL_PW` : TeamCity DB 계정 비밀번호
* `MYSQL_EXT_PORT` : TeamCity DB 접속용 포트
   
#### 2. `docker-compose.yml` 파일을 작성한다.
***docker-compose.yml***
```yaml
version: '3.7'

services:
  teamcity-db:
    container_name: teamcity-db
    image: mysql
    restart: always
    volumes:
      - ./db_data:/var/lib/mysql
      - ./db_conf:/etc/mysql/conf.d:ro
      - ./db_log:/var/log/mysql:ro
    environment:
      MYSQL_DATABASE: "${MYSQL_DB_NAME}"
      MYSQL_ROOT_PASSWORD: "${MYSQL_ROOT_PW}"
      MYSQL_ROOT_HOST: '${MYSQL_ROOT_HOST}'
      MYSQL_USER: "${MYSQL_USER}"
      MYSQL_PASSWORD: "${MYSQL_PW}"
    command: ['--character-set-server=utf8mb4', '--collation-server=utf8mb4_unicode_ci']
    ports:
      - "${MYSQL_EXT_PORT}:3306"

  teamcity:
    container_name: teamcity
    image: jetbrains/teamcity-server:${TEAMCITY_VERSION}
    restart: always
    ports:
      - "${TEAMCITY_EXT_PORT}:8111"
    volumes:
      - ./teamcity_data:/data/teamcity_server/datadir
      - ./teamcity_log:/opt/teamcity/logs
    environment:
      - TEAMCITY_HTTPS_PROXY_ENABLED=true
    depends_on:
      - teamcity-db

  teamcity-agent-001:
    container_name: teamcity-agent-001
    image: jetbrains/teamcity-agent:${TEAMCITY_VERSION}-linux-sudo
    restart: always
    user: root
    privileged: true
    volumes:
      - ./agents/agent-001/conf:/data/teamcity_agent/conf
    environment:
      - DOCKER_IN_DOCKER=start
```
> 포스팅 완료 후 상단에 `Incorrect proxy server configuration detected: Insecure Tomcat connector attributes`와 같은 경고가 발생하여
> `teamcity` 컨테이너의 `environment`에 `TEAMCITY_HTTPS_PROXY_ENABLED=true`를 추가하였다.
> [Insecure Tomcat connector attributes: missing secure attributes](https://youtrack.jetbrains.com/issue/TW-68935/Insecure-Tomcat-connector-attributes-missing-secure-attributes)를 참고하였다.

#### 3. `Agent`용 설정 파일 추가
1. `Agent`용 설정 파일 경로 생성 및 설정파일 작성
   ```shell
   $ mkdir -p agents/agent-001/conf
   $ vi agents/agent-001/conf/buildAgent.properties
   ```
   
1. `Agent`용 설정 파일 예시

   ***buildAgent.properties***
   ```properties
   name=Agent-001
   ownPort=9090
   serverUrl=https\://your.teamcity.domain
   
   workDir=../work
   tempDir=../temp
   systemDir=../system
   
   teamcity.docker.use.sudo=true
   ```
   * `TeamCity`는 `Agent` 3개까지 무료로 사용 할 수 있다. 필요한 만큼 agent 설정 파일을 작성한다.
   * `your.teamcity.domain`은 `TeamCity` 서버의 도메인 주소를 입력한다.

#### 4. 그 외 마운트용 경로 생성
```shell
# DB 설정 파일 경로 생성
$ mkdir -p db_conf

# DB 데이터 저장 경로 생성
$ mkdir -p db_data

# DB 로그 저장 경로 생성
$ mkdir -p db_log

# TeamCity 데이터 저장 경로 생성
$ mkdir -p teamcity_data

# TeamCity 로그 저장 경로 생성
$ mkdir -p teamcity_log
```

#### 5. 전체 디렉토리 구조는 다음과 같다.
```bash
$ tree .
.
├── agents
│   ├── agent-001
│   │   └── conf
│   │       └── buildAgent.properties
│   ├── agent-002
│   │   └── conf
│   │       └── buildAgent.properties
│   └── agent-003
│       └── conf
│           └── buildAgent.properties
├── db_conf
├── db_data
├── db_log
├── docker-compose.yml
├── teamcity_data
└── teamcity_log

12 directories, 4 files
```

### TeamCity 설치
#### 1. `docker-compose`를 이용하여 `TeamCity`를 설치한다.
```shell
$ docker-compose up -d
WARNING: The Docker Engine you're using is running in swarm mode.

Compose does not use swarm mode to deploy services to multiple nodes in a swarm. All containers will be scheduled on the current node.

To deploy your application across the swarm, use `docker stack deploy`.

Pulling teamcity-db (mysql:)...
latest: Pulling from library/mysql
e2c03c89dcad: Downloading [=====================>                             ]   19.2MB/44.88MB
68eb43837bf8: Download complete

# ...

Status: Downloaded newer image for jetbrains/teamcity-agent:2023.05-linux-sudo
Creating teamcity-db        ... done
Creating teamcity-agent-001 ... done
Creating teamcity           ... done
```

## 외부 연결 설정
> `nginx`를 이용하여 외부에서 접속 할 수 있도록 설정한다.
> `certbot`을 이용하여 SSL 인증서를 발급받아, `/etc/nginx/ssl` 경로에 저장하였다.

### 1. 설정파일 추가
1. `nginx` 설정 경로로 이동하여, `teamcity` 설정 파일을 생성한다.
   ```shell
   $ cd /etc/nginx/sites-available
   
   $ vi teamcity.conf
   ```

1. `nginx` 설정 파일 예시
   ***teamcity.conf***
   ```nginx
   server {
   	listen 80;
   	listen [::]:80;
   
   	server_name your.teamcity.domain;
   	return 301 https://$host$request_uri;
   }
   
   server {
   	listen 443 ssl;
   	server_name your.teamcity.domain;
   
   	ssl_certificate /etc/nginx/ssl/your.teamcity.domain.crt;
   	ssl_certificate_key /etc/nginx/ssl/your.teamcity.domain.key;
   
   	ssl_session_cache shared:SSL:1m;
   	ssl_session_timeout 5m;
   
   	ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
   	ssl_ciphers "HIGH:!aNULL:!MD5 or HIGH:!aNULL:!MD5:!3DES";
   	ssl_prefer_server_ciphers on;
   
   	location / {
   		proxy_pass http://localhost:xxxx/;
   		proxy_http_version 1.1;
   		proxy_set_header X-Forwarded-For $remote_addr;
   		proxy_set_header Host $server_name:$server_port;
   		proxy_set_header Upgrade $http_upgrade;
   		proxy_set_header Connection "upgrade";
   	}
   }
   ```
   * `your.teamcity.domain`은 `TeamCity` 서버의 도메인 주소를 입력한다.
   * `xxxx`는 `TeamCity` 서버의 `docker-compose.yml` 파일에서 `TEAMCITY_EXT_PORT`에 입력한 포트 번호를 입력한다.
   * `ssl_certificate`와 `ssl_certificate_key`는 `certbot`을 이용하여 발급받은 인증서 경로를 입력한다.
   * `proxy_set_header Connection "upgrade";`는 `TeamCity`에서 `websocket`을 사용하기 위해 설정한다.

### 2. `nginx` 설정 파일 링크
1. `nginx` 설정 파일 경로로 이동하여, `teamcity` 설정 파일을 링크한다.
   ```shell
   $ cd /etc/nginx/sites-enabled
   
   $ ln -s /etc/nginx/sites-available/teamcity.conf teamcity.conf
   ```

### 3. `nginx` 재시작
1. `nginx` 설정 문법 체크
   ```shell
   $ sudo nginx -t
   nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
   nginx: configuration file /etc/nginx/nginx.conf test is successful
   ```
   문법체크를 통과하면 `nginx`를 재시작한다.

1. `nginx` 재시작
   ```shell
   $ sudo service nginx restart
   $ sudo service nginx status
   ● nginx.service - A high performance web server and a reverse proxy server
   Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2023-07-09 15:46:03 KST; 5s ago
   Docs: man:nginx(8)
   # ...
   ```

## `TeamCity` 초기 설정
> `TeamCity` 서버에 접속하여 초기 설정을 진행한다.

### 1. `TeamCity` 서버 접속
![TeamCity First Start](/assets/img/post/infra/teamcity-in-docker/001.png)
* `https://your.teamcity.domain`로 접속한다.
   * `your.teamcity.domain`은 `TeamCity` 서버의 도메인 주소를 입력한다.
* `Proceed`를 클릭하여 다음으로 이동한다. 기존 데이터를 복구 할 때는 `Restore from backup`를 클릭하여 복구를 진행한다.

### 2. DB 연결 설정
![Database connection setup](/assets/img/post/infra/teamcity-in-docker/002.png)
1. `Select the database type`의 값을 `MySQL`로 선택한다.
   * 별도로 DB 설정하지 않고, `Internal(HSQLDB)`를 선택하여 사용할 수도 있다.
2. `Download JDBC driver` 버튼을 클릭하여 DB 드라이버를 다운로드한다.
3. DB 접속 정보를 입력한다.
   * `Database host[:port]`의 값은 `teamcity-db`를 입력한다. `docker-compose.yml`에서 설정한 DB의 컨테이너 이름이다.
   * `Database name`의 값은 `.env` 파일의 `MYSQL_DB_NAME`에 설정한 값을 입력한다.
   * `User name`의 값은 `.env` 파일의 `MYSQL_USER`에 설정한 값을 입력한다.
   * `Password`의 값은 `.env` 파일의 `MYSQL_PW`에 설정한 값을 입력한다.
4. 필수값 입력 후 활성화 되는 `Proceed` 버튼을 클릭하여 다음으로 이동한다.

### 3. 라이센스 동의
DB 생성 및 초기화가 완료되면, `TeamCity` 라이센스 동의 화면(`License Agreement for JetBrains® TeamCity®`)이 나타난다.
맨 하단으로 스크롤하여 `Accept license agreement`를 체크 후 활성화 되는 `Continue` 버튼을 클릭하여 다음으로 이동한다.

### 4. 관리자 계정 생성
![Create administrator account](/assets/img/post/infra/teamcity-in-docker/003.png)
1. 생성 할 관리자의 ID/Password를 입력한다.
2. `Create Account` 버튼을 클릭하여 관리자 계정을 생성한다.

## `TeamCity` 설정
> 초기설정 완료 후 `Agent` 설정 및 도메인, Email 알림 설정 방법에 대해 알아본다.

### 1. `Agent` 설정
![TeamCity Agent](/assets/img/post/infra/teamcity-in-docker/004.png)
1. 상단 메뉴에서 `Agents`를 클릭한다.
2. `Unauthorized` 항목 하위의 `Agent`를 클릭한다.
   * `docker-compose`를 통해 추가된 `Agent-001`이 목록이 표시된다. 이를 클릭한다.
   * 목록이 표시되지 않은 경우 `Unauthorized`왼편의 `>`를 클릭하여 하위 목록을 표시한다.

![Authorize Agent-001](/assets/img/post/infra/teamcity-in-docker/005.png)
1. `Authorize...` 버튼을 클릭하여 `Authorize Agent-001` 다이얼로그를 표시한다.
2. 필요한 경우 `Agent`에 대한 설명을 기입한다.
3. `Authorize` 버튼을 클릭하여 `Agent`를 인증한다.

### 2. 도메인 설정
![TeamCity Administration](/assets/img/post/infra/teamcity-in-docker/006.png)
1. 상단 메뉴에서 `Administration`를 클릭한다.
2. 좌측 메뉴에서 `Server Administration` > `Global Settings`를 클릭한다.
3. `Server URL`의 값을 `https://your.teamcity.domain`으로 변경한다.
   * `your.teamcity.domain`은 `TeamCity` 서버의 도메인 주소를 입력한다.
4. 상단에 표시되는 몇가지 경고문은 이 설정이 완료되면 잠시 후 사라진다.
   * 이때 `nginx` 설정의 `proxy_set_header Connection "upgrade";`가 필요하다. 
5. `Save` 버튼을 클릭하여 저장한다.

### 3. Email 알림 설정
![TeamCity Administration](/assets/img/post/infra/teamcity-in-docker/007.png)
1. 좌측 메뉴에서 `Server Administration` > `Email Notifier`를 클릭한다.
2. 자신의 SMTP 서버 정보를 입력한다. 참고로 Gmail(G-Suite)을 이용하는 경우 아래 값을 참고하여 입력한다.
   * `SMTP host` : `smtp.gmail.com`
   * `SMTP port` : `587`
   * `Send email messages from` : `TeamCity`에서 알림 메일 발송시 보내는 메일주소를 사용 할 메일 주소를 입력한다.
   * `SMTP login` : 자신의 Gmail 계정을 입력한다.
   * `SMTP password` : 자신의 Gmail 계정의 비밀번호를 입력한다.
   * `Secure connections` : `StartTLS`를 선택한다.
3. 하단의 `Test Connection` 버튼을 클릭하여 설정이 정상적으로 되었는지 확인한다.
4. `Save` 버튼을 클릭하여 저장한다.

## 마치며...
여기까지 설정하면 `TeamCity` 사용을 위한 기본적인 설정이 완료 되었다.
다음 포스트에서는(언제일지 알 수 없지만...) `TeamCity`를 이용하여 `CI/CD`를 구성하는 방법에 대해 알아보도록 하겠다.


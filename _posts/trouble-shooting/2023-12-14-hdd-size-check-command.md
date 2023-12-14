---
layout: post
title: HDD 용량 부족으로 Docker 빌드가 되지 않는 문제.
date: 2023-12-14 10:59
description: Docker pull push build가 전반적으로 이상하게 작동하는 문제가 발생하여 문제를 해결하는 과정을 정리한다.
comments: true
categories: [Trouble Shooting]
tags: [Trouble Shooting, Docker, HDD, df, du]
---

## 시작하며...
사내 도커 이미지 저장소(`Nexus3`)에서 이미지를 `pull` `push` 하는데 오류가 발생하는 문제가 발생하였다.
이를 해결했던 과정을 정리하고자 한다.

## 발단
최초 문제는 개발서버에 서비스 도커 이미지를 배포하기위해 `pull`하는 중 오류가 발생 했다.
```shell
$ docker pull docker.bud-it.com/my-container:latest
latest: Pulling from my-container
661ff4d9561e: Pull complete
# ...
84546ed93c51: Pull complete
e58022ddc24d: Downloading [=========================>]  331.5MB/331.5MB
f3bce65d4a18: Download complete
6bfc97bccde4: Download complete
unexpected EOF
```
위 명령 실행 결과의 `e58022ddc24d` 부분에서 Retry가 몇번 발생하더니 종국에는 `unexpected EOF` 오류가 발생하였다.

도커 이미지 푸시가 잘 못 된 건가 하는 생각에, 도커이미지 빌드하는쪽 서버에서 도커 이미지 삭제 후 다시 빌드(이때는 오류가 없었다.) `push`를 진행하니 아래와 같은 오류가 발생하였다.
```shell
$ docker push docker.bud-it.com/my-container:latest
The push refers to repository [docker.bud-it.com/my-container]
3e0cb1b60df2: Layer already exists
8237927df458: Layer already exists
4bff2a4bdbcb: Pushing [=========================>]  343.7MB/343.7MB
# ...
5af4f8f59b76: Layer already exists
received unexpected HTTP status: 500 Internal Server Error
```
이번에는 위 명령 실행 결과의 `4bff2a4bdbcb` 부분에서 Retry가 몇번 발생하더니, 결국 `500 Internal Server Error`가 발생 하였다.

여러 시도를 진행 하던 중, 이미지를 새로 빌드해서 시도해 보자는 생각에 소스코드, 도커이미지 등 관련 자료를 모두 삭제하고, 새로 소스코드 clone 하여, 빌드 중 아래와 같은 오류가 발생하였다.
```shell
$ docker-compose build my-container
Building my-container
ERROR: failed to update builder last activity time: write /home/xxx/.docker/buildx/activity/.tmp-default819006932: no space left on device
ERROR: Service 'my-container' failed to build : Build failed
```
오류 날게 없는데 하면서 헤메던 중, `no space left on device`라는 문구가 (다행히)눈에 들어왔고, 결론은 HDD용량이 가득 차서 빌드에 실패하고 있었다.

> 아마도 그 전단계(빌드는 성공하던 단계)에서는 용량이 미묘하게 부족해서 빌드는 완료 되었지만, 도커 이미지가 불완전한 상태로 생성된 것이 아닐까 추측된다.

## HDD 용량 확보
HDD 용량 확인 명령은 간단하게 `df`정도만 알고 있던 상황이었다.
```shell
$ df -h
파일 시스템     크기  사용  가용 사용% 마운트위치
tmpfs           1.6G  3.7M  1.6G    1% /run
/dev/sda2       219G  208G     0  100% /
# ...
tmpfs           1.6G   76K  1.6G    1% /run/user/125
tmpfs           1.6G   64K  1.6G    1% /run/user/1000
```

루트 마운트 영역이 100% 사용된 상태인데 어느 디렉토리가 용량을 차지하는지 확인하는 방법을 몰라서, 인터넷 검색하니 `du`라는 명령이 있단다.
```shell
$ cd /
$ sudo du -h --max-depth=1
178G	./var
9.2G	./snap
# ...
$ cd /var
$ sudo du -h --max-depth=1
12K	./www
174G	./lib
4.0K	./local
# ...
$ cd /lib
$ sudo du -h --max-depth=1
169G	./docker
36K	./PackageKit
# ...
```

결국 도커 관련 파일이 용량을 전부 잡아먹고 있는듯 했고, `/var/lib/docker` 경로에는 도커의 임시파일이나, 이미지, 컨테이너 관련 파일이 누적되면서 용량이 커질 수 있다고 한다.

아래 과정으로 일단 용량을 확보했다.
```shell
$ sudo bash -c 'du -sh /var/lib/docker/*'
# ...
292K	/var/lib/docker/network
165G	/var/lib/docker/overlay2
16K	/var/lib/docker/plugins
# ...
$ docker system prune -a -f
Deleted Networks:
ext_service
jenkins_default
# ...

Deleted Images:
untagged: docker.bud-it.com/my-container@sha256:ad165c92e2664fe5e1448ee6e537e4a1fcf7c27981af5f4aaed4647b14af50d4
deleted: sha256:296cb2ed8ff4bb20d81e73c6f4a108b5a68897d2aa547b3c7b23b473db768be1
# ...

Deleted build cache objects:
etnygvxjmrfbs8cvly48c2ljq
vqsbpghffrl6bwbrk344esc2d
# ...

Total reclaimed space: 124.4GB
$ sudo bash -c 'du -sh /var/lib/docker/*'
# ...
292K	/var/lib/docker/network
29G	/var/lib/docker/overlay2
16K	/var/lib/docker/plugins
# ...
```
`overlay2`의 용량이 "165G"에서 "29G"로 정리되었고, 이후 `build`, `push`, `pull` 모두 정상 작동하였다.

## 추가조치
### 1. HDD 용량 모니터링
HDD 용량을 모니터링 해서, 사용량이 80%가 넘어가는 마운트영역이 발생하면, 슬랙으로 알림을 받도록 스크립트를 작성하여 `crontab`에 등록하였다.
스크립트 작성은 GPT에게 부탁했다.
```bash
#!/bin/bash

# 슬랙 웹훅 URL 설정
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"

# df -h 결과를 파일에 저장
df -h > /tmp/df_output.txt

# 사용량이 80%를 초과하는 파티션 찾기
ALERT_PARTITIONS=$(awk 'NR>1 {sub(/%/, "", $5); if($5 >= 80) print}' /tmp/df_output.txt)

# 경고 메시지 전송
if [ ! -z "$ALERT_PARTITIONS" ]; then
    # df -h 결과를 JSON 형식으로 변환
    DF_RESULT=$(cat /tmp/df_output.txt | sed 's/$/\\n/' | tr -d '\n')

    # 슬랙으로 메시지 전송
    curl -X POST --data-urlencode "payload={\"text\": \"Disk Usage Alert!\n\`\`\`$DF_RESULT\`\`\`\"}" $SLACK_WEBHOOK_URL
fi

```

### 2. `/var/lib/docker` 경로 조정(미적용)
다음의 절차를 통해서 `/var/lib/docker` 경로를 용량이 충분한 다른 HDD 경로로 조정 할 수 있다고 한다.
현재 설정된 경로에 있는 데이터를 단순히 복사만 하고 경로 조정을 하면 되는것인지 알 수 없어서, 일단 적용은 하지 않고 있는 상태이다.

1. `/etc/docker/daemon.json`파일 수정
```json
{
    "graph": "/ext/docker/"
}
```
_/etc/docker/daemon.json_

2. Docker 재기동
```shell
$ sudo service docker stop
$ sudo service docker start
```

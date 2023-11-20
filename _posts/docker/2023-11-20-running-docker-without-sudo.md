---
layout: post
title: Ubuntu에서 sudo 없이 docker 명령 사용하도록 설정
date: 2023-11-20 15:19
description: Ubuntu에서 sudo 없이 docker 명령 사용하도록 설정하는 방법을 기술한다.
comments: true
categories: [Docker]
tags: [Docker, Setting, Ubuntu, Ubuntu 22.04]
---

## 시작하며...
MacOS와 Ubuntu에서 병행으로 docker를 사용하면서, Ubuntu에서 `sudo`를 빼먹고 명령을 사용하는 경우가 자주 발생하여,
Ubuntu에서 `sudo` 없이 docker 명령을 사용 할 수 있도록 설정 할 수 있는지 알아보았다.

## 이번 포스팅에서는...
이번 포스팅에서는 Ubuntu에서 `sudo` 없이 docker 명령을 사용 할 수 있도록 설정하는 방법에 대해 기술한다.

## 설정 순서
막상 자료를 조사해 보니. 설정은 단순했다. docker 그룹을 추가하고, (`sudoers`에 등록 된)현재 사용자를 docker 그룹에 추가하는 것이 전부였다.
```shell
$ sudo groupadd docker
$ sudo usermod -aG docker $USER
```

위 설정만으로 끝이 었다. 참조한 자료에는 시스템을 재기동 해야 한다는 이야기가 있었지만, 나의 경우에는 바로 적용이 되었다.

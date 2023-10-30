---
layout: post
title: MacOS에서 k3s 테스트 환경 구성
date: 2023-10-20 15:56
description: MacOS에서 k3s 테스트 환경 구성 방법을 기술한다.
comments: true
categories: [ Infra, Kubernetes ]
tags: [ Kubernetes, K8s, K3s, Setting ]
---

## 시작하며...
사내 개발중이던 시스템을 실제 운영 단계에서 어떻게 관리 할 것인지 고민하던 중, `Kubernetes`를 사용 하는 것으로 의사결정하였고,
인프라 전문가가 없는 상황에서 개념 이해에 시간을 꽤 사용 한 후 `k3s`를 알게 되었고, [k3s 문서 페이지](https://docs.k3s.io/kr/)의
적합한 환경 설명 중 `k8s 클러스터 분야의 박사 학위를 취득하기 어려운 상황` 이라는 문구가 마음에 와닿아 사용해 보기로 결정 하였다.

## k3s란?
`k3s`에 대한 자세한 설명은 [k3s 문서 페이지](https://docs.k3s.io/kr/)를 참고하길 바란다.
내가 이해한 `k3s`는 쿠버네티스의 경량화 버전으로, 쿠버네티스의 모든 기능을 지원하지는 않으나, 우리 서비스를 구성하는데 필요한
기능은 지원이 될 것으로 생각된다.
현재 서비스 적용을 위해 테스트 진행한 사항으로는 `MongoDB`, `MariaDB`, `Spring boot` 프로젝트 `docker` 이미지를 생성하여,
각 컨테이너(이후부터는 파드로 명칭을 변경한다.)간 통신이 이루어지는 것 까지 확인이 완료 되었다.

> 왜 이름이 `k3s`인가에 대해 공식 문서에 기술 되어 있는데, 간단히 소개하자면, `k3s`는 쿠버네티스의 절반 크기의 메모리를 사용하도록
> 하는 것이 목표이며, `k8s`는 10글자이므로, 그 절반인 5글자의 이름이라면 `k3s`가 되어야 하므로 이름을 `k3s`로 지었다고한다.
> 그러므로 `k3s`는 `Kubernetes`와 같은 긴이름이 존재하지 않고, 공식적인 발음도 없다고 명시되어 있다.
> 이후 `k3s`표기 할 것이며, 개발자간 커뮤니케이션을 위해서 `케이쓰리에스`로 발음하도록 하겠다.

## k3s 설치
먼저 `k3s`를 로컬(MacOS)환경에서 테스트를 진행하기 위해서 로컬에 `Ubuntu` VM을 3개 생성하고, 1개의 마스터노드와 2개의 워커노드로 구성하여,
테스트를 진행 하였다. 이 진행 절차에 대해 설명을 진행하고자 한다.

### multipass 설치 및 가상머신 생성
`multipass`는 `Ubuntu`를 로컬에서 가상머신으로 실행할 수 있도록 도와주는 도구이다.

1. `multipass` 설치
   ```shell
   $ brew install --cask multipass
   ```
2. `multipass`로 설치 가능한 `Ubuntu` 버전 목록 확인
   ```shell
   $ multipass find
   Image                       Aliases           Version          Description
   20.04                       focal             20231011         Ubuntu 20.04 LTS
   22.04                       jammy,lts         20231026         Ubuntu 22.04 LTS
   23.04                       lunar             20231025         Ubuntu 23.04
   
   ...
   ```
   `Aliases`항목의 이름을 이용하여 가상머신을 생성한다. 나는 마지막 LTS 버전인 22.04버전(Aliases: `jammy`)를 사용하였다.
3. `Ubuntu`가상머신 생성 및 실행
   ```shell
   $ multipass launch --name k3s-master --cpus 1 --memory 1G --disk 5G jammy
   $ multipass launch --name k3s-worker1 --cpus 1 --memory 1G --disk 5G jammy
   $ multipass launch --name k3s-worker2 --cpus 1 --memory 1G --disk 5G jammy
   ```
   - `--name`: 가상머신 이름
   - `--cpus`: 가상머신 CPU 코어 수
   - `--memory`: 가상머신 메모리 크기
     - 인터넷 샘플로 찾아낸 명령어에는 `--mem`으로 되어 있었지만 이 옵션은 `deprecated`되었다. `--memory`로 사용해야 한다.
   - `--disk`: 가상머신 디스크 크기
   - `jammy`: `multipass find` 명령어로 확인한 `Ubuntu` 버전
4. `multipass`로 생성한 가상머신 목록 확인
   ```shell
   $ multipass list
   Name                    State             IPv4             Image
   k3s-master              Running           192.168.65.2     Ubuntu 22.04 LTS
   k3s-worker1             Running           192.168.65.3     Ubuntu 22.04 LTS
   k3s-worker2             Running           192.168.65.4     Ubuntu 22.04 LTS
   ```
   마스터 노드용으로 1개의 가상머신(`k3s-master`)을 생성하고, 워커 노드용으로 2개의 가상머신(`k3s-worker1`, `k3s-worker2`)을 생성하였다.

### `Ubuntu` 가상머신에 `k3s` 설치
1. 마스터노드 설치
   ```shell
   $ multipass exec k3s-master -- /bin/bash -c "curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -"
   [INFO]  Finding release for channel stable
   [INFO]  Using v1.27.6+k3s1 as release
   [INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.27.6+k3s1/sha256sum-arm64.txt
   [INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.27.6+k3s1/k3s-arm64
   [INFO]  Verifying binary download
   [INFO]  Installing k3s to /usr/local/bin/k3s
   ...
   ```
   - `K3S_KUBECONFIG_MODE="644"` 는 k3s installer 에게 kubectl 이 클러스터에 접근하기 위해 사용하는 설정 파일을 생성하도록 하는 옵션이다.
   - '--' 는 multipass 명령어와 실제 컨테이너 안에서 실행할 명령어를 구분하기 위해 사용한다.
2. 워커노드 설치에 사용 할 환경변수 설정
   ```shell
   $ K3S_NODEIP_MASTER="https://$(multipass info k3s-master | grep "IPv4" | awk -F' ' '{print $2}'):6443"
   $ K3S_TOKEN="$(multipass exec k3s-master -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")"
   
   $ echo $K3S_NODEIP_MASTER
   https://192.168.65.2:6443
   $ echo $K3S_TOKEN
   K10...
   ```
   마스터노드 정보와 접속을 위한 토큰 정보를 워커노드 설치시 직접 입력 할 수도 있지만, 워커노드가 여러개일 경우 환경변수로 추출하여 사용하는 편이 편리하다.
3. 워커노드 설치
   ```shell
   $ multipass exec k3s-worker1 -- /bin/bash -c "curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -"
   $ multipass exec k3s-worker2 -- /bin/bash -c "curl -sfL https://get.k3s.io | K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -"
   ```
   2개의 워커노드에 동일한 옵션으로 설치를 진행한다.
4. 관리용 PC(여기서는 MacOS)에 마스터노드 설정파일 복사
   > `kubectl` 명령이 이미 설치되어 있지 않다면, `brew install kubernetes-cli`명령으로 먼저 설치한다.
   ```shell
   $ multipass copy-files k3s-master:/etc/rancher/k3s/k3s.yaml ~/.kube/
   ```
   마스터노드 설치시 추가한 옵션(`K3S_KUBECONFIG_MODE="644"`)으로 인해, 마스터노드에 `k3s.yaml`파일이 생성되었다. 이파일을 관리용 PC의
   `~/.kube/`디렉토리로 복사한다.
5. `kubeconfig` 파일(`k3s.yaml`)의 내용 중 `server` 설정을 마스터노드를 바라보도록 수정한다.
   > `multipass list`로 확인한 마스터노드의 IP(이 예시에서는 `192.168.65.2`)를 바라보도록 수정한다.
   _k3s.yaml_
   ```yaml
   apiVersion: v1
   clusters:
   - cluster:
     certificate-authority-data: ...
     server: https://192.168.65.2:6443
     name: default
     contexts:
     ...
   ```
6. 마스터노드 관리용 명령어 생성
   > 자신의 쉡 스크립트용 설정파일(zsh 사용한다면, `~/.zshrc`)에 아래 alias를 추가한다.
   _.zshrc_
   ```bash
   alias k3sctl="kubectl --kubeconfig=${HOME}/.kube/k3s.yaml"
   ```
   이제 `k3sctl` 명령어로 마스터노드를 관리 할 수 있다.

   > 또는, `~/.kube/config` 파일을 위 `k3s.yaml` 파일로 덮어써서, 기본적인 `kubectl` 명령어의 기본 설정을 새로 설치한 `k3s` 마스터노드를
   > 관리하는 용도로 설정 할 수도 있다. 이 경우 혹시 별도로 설정한 `minikube` 또는 도커의 쿠버네티스 클러스터를 사용하는 설정이 덮어써질 수 있으니
   > 주의하자.

## 새롭게 알게된 내용
쿠버네티스를 (`minikube`를 설치하여)공부하면서 쿠버네티스는 마스터노드와 워커노드를 구분하여 설치해서 설정한다고 하는데, `kubectl` 명령으로 
지금은 `minikube`를 관리하는데, 실제 환경에서 마스터노드에 어떻게 명령을 내리는 것인지 계속 의문이었다.
이번 `k3s` 설정을 진행하면서, 각 마스터노드의 설정파일(위 예에서는 `k3s.yaml`)을 관리용 PC에 복사하여, `kubectl` 명령 사용시,
`--kubeconfig` 옵션으로 해당 설정파일을 지정하여 사용하면, 마스터노드를 관리 할 수 있음을 알게 되었다.

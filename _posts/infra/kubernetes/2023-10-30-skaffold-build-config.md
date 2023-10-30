---
layout: post
title: skaffold를 활용한 쿠버네티스 배포 자동화 구성
date: 2023-10-20 18:01
description: skaffold 설치 및 이를 활용한 쿠버네티스 배포 자동화 구성 방법에 대해 기술 한다.
comments: true
categories: [ Infra, Kubernetes ]
tags: [ Kubernetes, K8s, K3s, Skaffold, Setting ]
---

> 아래 내용은 사내 서비스 중 `grigo-chat`에 적용 과정을 정리한 내용으로 좀 더 보편적인  예제로 수정을 진행할 예정입니다.

## 시작하며...
`docker-compose`를 이용하여 서비스를 배포하던 것을 쿠버네티스를 이용하도록 변경을 진행하면서, 각 쿠버네티스 설정파일(`deployment`, `service` 등)이  
많아지고, 이를 수정하고 검증하는 과정에서 매번 `kubectl create`, `kubectl delete`를 반복하게 되었다.  
이를 해결 할 방법이 없을지 검토하는 과정에서 `skaffold`를 알게 되었고, 이를 활용하는 방법에 대해 스터디한 내용을 정리하고자 한다.  
이 포스팅을 읽기전에 [MacOS에서 k3s 테스트 환경 구성](/posts/k3s-macos-init/) 포스팅을 참고하여, 테스트 환경을 먼저 구축하길 추천한다.

## 이번 포스팅에서는...
이번 포스팅에서는 MacOS에 `skaffold`를 설치하고, 기존에 작성한 스프링부트 프로젝트에, `k3s`용으로 마리아DB 설정파일과 서비스 설정파일을  
추가하고, `skaffold`명령을 이용하여, 일괄 배포하는 과정에 대해 설명한다.

## skaffold란?
`skaffold`에 대한 자세한 설명은 [skaffold 문서 페이지](https://skaffold.dev/docs/)를 참고하길 바란다.  
내가 이해한 `skaffold`는 쿠버네티스 배포에 필요한 `yaml`파일을 목록화하고, 배포 전에 빌드가 필요한 경우 빌드 및 도커 이미지를 생성하는 과정을,  
설정파일로 작성하여 배치화 하는 것을 지원하는 도구로 이해되었다.

> 기존 작성된 프로젝트에 적용시, `docker-compose build`를 이용해서 이미지를 빌드하고, 사내 이미지 저장소에 푸시하고, 이를 이용하여  쿠버네티스에 배포하는 스크립트를 작성하는것이 오히려 펀리하진 않을까 하는 의심은 든다.
> 아직은 사내 표준으로 확정한 것은 아니고, 좀 더 사용해보고 배포 절차를 정형화 하는데 크게 도움이 되는 방향은 아니라고 판단이 되면, 별도로 공유하도록 하겠다.

## skaffold 설치
MacOS에서 설치 방법은 간단하다. 다음 한줄 명령으로 간단히 설치 할 수 있다.
```shell
$ brew install skaffold
```

## 빌드용 플러그인 설정 추가
`skaffold`를 이용하여 빌드 설정을 하기 위해서는 `jib`라는 구글 코드 플러그인을 `build.gradle`에 추가해 주어야 한다.
_build.gradle_
```groovy
// ...
plugins {
    // ...
    
    // jib 플러그인
    id 'com.google.cloud.tools.jib' version '3.4.0'  
}
// ...
```
> 2023-10-30 현재 플러그인 최신버전은 `3.4.0`이다.

## 쿠버네티스 배포용 설정 파일 추가
프로젝트 루트경로에 `k8s` 디렉토리를 생성하고, 하당 경로 하위에 쿠버네티스 배포에 필요한 `yaml` 파일들을 추가하였다.
### MariaDB 설정
`MariaDB` 데이터를 유지하기 위한 `PersistentVolume` 설정파일을 추가한다.
_k8s/mariadb-pv.yaml_
```yaml
apiVersion: v1  
kind: PersistentVolume  
metadata:  
  name: grigo-chat-mariadb-pv  
  labels:  
    type: local  
spec:  
  storageClassName: manual  
  capacity:  
    storage: 5Gi  
  accessModes:  
    - ReadWriteOnce # 한 파드에서만 접근 허용  
  hostPath: 
    path: "/foo/bar/mnt/grigo-chat/mariadb/"  
```
`hostPath.path`에 지정한 경로가 정확히 어떤 경로인지 아직 파악이 안되었다.
맨 처음에는 `docker-compose` 볼륨설정의 개념으로 생각했으나, 쿠버네티스는 실제 파드가 생성되는 위치는 워커노드이다. 각 워커 노드에 지정한 경로가 생성되고, 거기에 마운트가 되는 것인지, 아니면 다른 의미가 있는지 조금더 파악이 필요한 상태이다.
참고로 해당 `hostPath.path`의 값에는 `..`문자가 허용되지 않는다. 최초 볼륨설정 개념으로 이해하여 상대경로 설정 할려고 입력했더니 오류가 발생하더라...

다음으로 `PersistentVolume`을 파드에 연결 할 `PersistentVolumeClaim` 설정파일을 추가한다.
_k8s/mariadb-pvc.yaml_
```yaml
apiVersion: v1  
kind: PersistentVolumeClaim  
metadata:  
  name: grigo-chat-mariadb-pvc  
spec:  
  storageClassName: manual  
  accessModes:  
    - ReadWriteOnce  
  resources:  
    requests:  
      storage: 5Gi
```

다음으로 MariaDB 컨테이너 생성시 환경변수로 사용 할 설정값에 대한 정보를 쿠버네티스 `Secret`으로 등록한다. `Secret` 등록을 위해 먼저 `env` 파일에 환경변수 값을 설정해 준다.
_k8s/.mariadb.env_
```env
MYSQL_HOST=%  
MYSQL_PORT=3306  
MYSQL_ROOT_PASSWORD=root-password
MYSQL_DATABASE=db-name
MYSQL_USER=db-user-name 
MYSQL_PASSWORD=db-user-password
```
각 환경변수의 설정값으 본인의 환경에 맞도록 수정해준다.

아래명령을 이용하여, `env`로 작성된 환경변수값을 쿠버네티스 `Secret`에 등록 할 수 있다.
> [MacOS에서 k3s 테스트 환경 구성](/posts/k3s-macos-init/) 포스팅을 참고하여 `k3sctl` alias를 등록했다면 아래 명령을 그대로 사용 할 수 있다. `minikube`등을 사용하여 로컬에 적용시에는 `k3sctl`명령을 `kubectl`로 변경하여 실행해야한다. 이 설명은 이후로 계속 유효하다.
```shell
$ k3sctl create secret generic grigo-chat-mariadb-secret \
  --from-env-file=./k8s/.mariadb.env 
```

> 개인적으로는 아래 명령을 이용하여 `yaml`형식의 문자열을 취득하여, `k8s/mariadb-secret.yaml`파일로 추가하여 필요한 경우 secret 설정을 등록하고 삭제 할 수 있도록 하였다.
```shell
$ kubectl create secret generic grigo-chat-mariadb-secret \
  --from-env-file=./k8s/.mariadb.env \
  --dry-run=client \
  -o yaml
```

다음으로 디플로이먼트 설정을 추가하였다.
_k8s/mariadb-deployment.yaml_
```yaml
apiVersion: apps/v1  
kind: Deployment  
metadata:  
  name: grigo-chat-mariadb  
spec:  
  selector:  
    matchLabels:  
      app: grigo-chat-mariadb  
  strategy:  
    type: Recreate  
  template:  
    metadata:  
      labels:  
        app: grigo-chat-mariadb  
    spec:  
      containers:  
        - image: mariadb:11.1.2-jammy  
          name: grigo-chat-mariadb  
          envFrom:  
            - secretRef:  
                name: grigo-chat-mariadb-secret  
          ports:  
            - containerPort: 3306  
              name: mariadb  
          volumeMounts:  
            - mountPath: /var/lib/mysql  
              name: mariadb-data  
      volumes:  
        - name: mariadb-data  
          persistentVolumeClaim:  
            claimName: grigo-chat-mariadb-pvc
```

다음으로 서비스 설정을 추가하였다.
_k8s/mariadb-svc.yaml_
```yaml
apiVersion: v1  
kind: Service  
metadata:  
  name: grigo-chat-mariadb  
spec:  
  type: LoadBalancer  
  ports:  
    - port: 3306  
      name: mariadb  
      protocol: TCP  
      targetPort: 3306  
  selector:  
    app: grigo-chat-mariadb
```

### 사내 도커이미지 저장소용 인증정보 등록
이후 설정을 진행하기 전에 사내 도커이미지 저장소 `repo.bud-it.com`에서 도커 이미지를 `pull`할 때 사용 할 인증 정보를 `k3s` 시크릿 정보로 등록하는 작업을 진행하였다.
아래 명령을 이용하여 등록 할 수 있다.
```shell
$ k3sctl create secret docker-registry repo.bud-it.com \
  --docker-server=repo.bud-it.com \
  --docker-username=repo-user-name \
  --docker-password=repo-user-password \
  --docker-email=repo-user-email
```
`repo-user-xxxx`에 본인의 인증 정보를 입력하여 위 명령을 실행하면, 쿠버네티스 시크릿에 `repo.bud-it.com`이라는 이름의 시크릿이 등록된다. 이후 이 정보를 이용하여 파드를 생성하도록 설정을 진행 한다.

### 서비스용 쿠버네티스 설정파일 추가
이후 서비스용 `deployment`와 `service`정보를 추가한다.
먼저 `deployment`에시이다.
_k8s/grigo-chat-deployment.yaml_
```yaml
apiVersion: apps/v1  
kind: Deployment  
metadata:  
  name: grigo-chat  
  labels:  
    app: grigo-chat  
spec:  
  replicas: 1  
  selector:  
    matchLabels:  
      app: grigo-chat  
  template:  
    metadata:  
      labels:  
        app: grigo-chat  
    spec:  
      serviceAccountName: grigo-chat-service  
      containers:  
        - name: grigo-chat  
          image: repo.bud-it.com/grigo/grigo-chat:latest  
          ports:  
            - containerPort: 8080  
          env:  
            - name: SPRING_PROFILES_ACTIVE  
              value: "kube"  
      imagePullSecrets:  
        - name: repo.bud-it.com
```

다음으로 서비스를 추가한다.
_k8s/grigo-chat-service.yaml_
```yaml
apiVersion: v1  
kind: Service  
metadata:  
  name: grigo-chat  
  labels:  
    app: grigo-chat  
    spring-boot: "true"  
spec:  
  ports:  
    - port: 8080  
      protocol: TCP  
      targetPort: 8080  
  selector:  
    app: grigo-chat  
  type: LoadBalancer  
```

`deployment` 설정에서 사용한 `serviceAccountName`의 설정을 추가해 준다.
> 이 설정은 이후에 추가될 MSA간 공통화 처리를 위한것이 아닌가 추측하고 있다. 현재는 정확한 용도를 알지 못하지만, 오류가 발생하지 않고 서비스가 올라가도록 인터넷에서 찾은 샘플파일을 참조하여 아래와 같이 작성하였다.

_k8s/privileges.yaml_
```yaml
apiVersion: v1  
kind: ServiceAccount  
metadata:  
  name: grigo-chat-service  
---  
kind: ClusterRole  
apiVersion: rbac.authorization.k8s.io/v1  
metadata:  
  name: grigo-chat-service  
  namespace: default  
rules:  
  - apiGroups: [""]  
    resources: ["configmaps", "pods", "services", "endpoints", "secrets"]  
    verbs: ["get", "list", "watch"]  
---  
kind: ClusterRoleBinding  
apiVersion: rbac.authorization.k8s.io/v1  
metadata:  
  name: grigo-chat-service  
subjects:  
  - kind: ServiceAccount  
    name: grigo-chat-service  
    namespace: default  
roleRef:  
  apiGroup: rbac.authorization.k8s.io  
  kind: ClusterRole  
  name: grigo-chat-service
```
`ServiceAccount`의 `metadata.name`의 값이 `Deployment`의 `serviceAccountName`의 값과 일치하도록 해준다.
## skaffold 설정파일 추가 및 배포
`skaffold` 명령을 사용하기 위해서는 먼저 프로젝트 루트에 `skaffold.yaml` 파일이 추가되어야 한다.
아래 명령을 이용하여 간단히 추가 할 수 있다. 생성된 `skaffold.yaml`을 수정 할 예정이므로, 실행 후 표시되는 프롬프트에 아무 값이나 선택하여 파일을 생성해 준다.
```shell
$ skaffold init
```

명령을 실행 후 프롬프트에 적당히 답변을 해주면 `skaffold.yaml`파일이 생성된다. 파일을 열어서 아래와 같이 수정해준다.
> 인터넷의 예제들은 `apiVersion: skaffold/v4beta5`였다. 아마 현재 설치된 `skaffold` 버전에 따라 설정 값이 달라지는듯 하다. `apiVersion`은 생성된 대로 유지하고, 나머지는 아래 내용을 참고하여 수정해 준다.

_skaffold.yaml_
```yaml
apiVersion: skaffold/v4beta7  
kind: Config  
metadata:  
  name: grigo-chat  
build:  
  artifacts:  
    - image: repo.bud-it.com/grigo/grigo-chat  
      jib:  
        args:  
          - -DskipTests  
#      buildpacks:  
#        builder: gcr.io/buildpacks/builder:v1  
  tagPolicy:  
    sha256: {}  
manifests:  
  rawYaml:  
    - k8s/mariadb-*.yaml  
    - k8s/grigo-chat-*.yaml  
    - k8s/privileges.yaml  
```
- `gradle` 프로젝트라면, `build` 설정부분이 위 주석부분처러 설정되어 있을 것이다. 삭제하고 `jib`설정을 추가해 준다. 앞에서 `build.gradle`에 추가한 `com.google.cloud.tools.jib` 플러그인을 이용하여 빌드하는 설정이다.
- `tagPolicy` 설정을 추가해 준다. 위와같이 설정하면 빌드 후 도커 이미지를 생성 할 때, 고정값으로 `latest` 태그로 이미지 파일이 생성된다.
- `rawYaml` 설정 부분은 `k8s` 디렉토리에 추가한 `yaml`파일들 목록이 작성되어 있을 것이다. 위와같이 간소화 하여 관리 할 수 있다. 파일에 `prefix`사용 한 이유는 필요한 설정의 묶음들을 좀 더 편리하게 추가/제외 할 수 있도록 하기 위함이다.

여기까지 따라했다면, `skaffold`를 사용 할 준비가 완료되었다.
아래 명령을 통해서 `build` -> `docker`이미지 생성 -> 쿠버네티스배포를 일괄 처리 할 수 있다.
[MacOS에서 k3s 테스트 환경 구성](/posts/k3s-macos-init/)에서 설정한 `k3s` 환경에 배포가 될 수 있도록 `--kubeconfig` 옵션을 사용하였다. 로컬에 설정한 `minikube`등을 사용한다면, 옵션 없이 간단히 사용이 가능하다.
```shell
$ skaffold dev --kubeconfig ~/.kube/k3s.yaml
```
위와같이 `dev` 명령을 이용하면, 배포 후 로그가 표시되고, 소스에 수정이 발생하는지 모니터링하여, 변경이 있을 경우 자동으로 빌드부터 배포를 진행한다. 또한 로그 표시중 `Ctrl+C`로 중지하면, 배포되어 있는 설정들을 일괄 삭제한다. 개발 진행시 유용한 명령이다.

실제 배포를 진행 할때는 아래와 같이 `run` 명령을 이용한다.
```shell
$ skaffold run --kubeconfig ~/.kube/k3s.yaml
```

또는 여러 환경을 테스트 하기 위해서 `skaffold.yaml` 파일을 `skaffold-local.yaml`로 복사하고, 내용을 수정 후 해당 파일을 이용하하기 위해 아래와 같이 `--filename` 옵션을 이용 할 수도 있다.
```
$ skaffold dev --kubeconfig ~/.kube/k3s.yaml --filename skaffold-local.yaml
```

## 고민사항
`dev` 명령으로 배포 테스트 및 중지시 일괄 삭제 등 유용한 기능이 많다. 배운게 도둑질이라고, 쉘 스크립트로 배치화 하는 것이 그리 큰 공수가 들어가는 일이 아니고, 마음에 쏙 들도록 설정하기 위해서 `skaffold` 러닝커브를 생각하면, 그냥 스크립트를 작성하는편이 더 나은 선택이 아닐지 계속 고민중이다.
도커 이미지를 생성하고, 저장소에 push를 한다던지 하는 업무 프로세스를 추가하려면 어떻게 해야 할지 등 고민이 되는 내용이 있는 상태이며, 현재 CI 도구로 사용중인 `Teamcity`를 이용하는데, 스크립트를 이용하고 있는 상태에서, `skaffold` 사용을 위해서 CI 서버에 도구를 설치하고 이용하도록 구성을 변경하는것도 불필요한 작업이 아닐까 하는 생각도 있다.
어떻게 하는것이 향후 빌드 배포를 좀 더 정형화 하는데 도움이 될지에 대해서 아직 고민중인 상태이다.

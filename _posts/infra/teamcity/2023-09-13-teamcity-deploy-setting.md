---
layout: post
title: Teamcity 배포 설정 예시
date: 2023-09-13 10:58
description: Teamcity에서 배포 설정에 대한 예시를 작성한다.
comments: true
categories: [Infra, Teamcity]
tags: [Teamcity, Setting, Deploy, Build, CI/CD]
---

> `Teamcity`에서 배포 설정 진행 내용을 바탕으로 현재 구성된 내용을 정리한다.

## 개요
사내 프로젝트의 빌드/배포 설정을 완료하였다. 이를 기반으로 `Teamcity`에서 배포를 위한 설정 방법에 대해 샘플 프로젝트를 생성하여 설명하고자 한다.
빌드 및 배포 과정에는 2개의 Agent를 이용하도록 구성하였고, `Docker`를 이용하여 기동되어 있는 Agent는 도커 이미지 빌드 및 빌드 된 이미지를 
사내 저장소에 Push하는 역할을 담당하고, 각 서버에 설치되어 있는 Agent는 사내 저장소에 Push된 이미지를 Pull하여 배포하는 역할을 담당한다.

위와 같이 구성한 이유는 비교적 리소스를 많이 사용하는 도커 이미지 빌드를 `Docker container` 내부에서 실행 하므로서, CI/CD 서버에 부하를 줄이고자 하였다.

정리하는 내용은 각 메뉴에 대한 상세 설명은 최대한 생략하고, 프로젝트 추가 및 빌드/배포 설정을 구분하여 구성 후 각 담당 Agent에서 실행 할 수 있도록
설정을 할당하는 방법에 대해 설명한다.

## 작업 절차
### 프로젝트 등록
먼저 프로젝트 추가를 위해 `Teamcity` 상단의 `Projects`메뉴 우측의 `+`버튼을 클릭한다.
![Create Project 버튼](/assets/img/post/infra/teamcity/teamcity-deploy-setting/001.png)

`Create Project` 화면이 표시되면, 프로젝트 정보를 입력해 준다. 이 포스팅에서는 소스 없이 빌드/배포 설정 과정을 설명하므로,
`Manually`를 선택 했지만, 상단 버튼 중 사용하는 저장소에 맞는 버튼을 클릭하여 소스를 연결하여 설정하도록 한다.
![Create Project](/assets/img/post/infra/teamcity/teamcity-deploy-setting/002.png)
1. `Manually` 버튼을 클릭한다.
2. 프로젝트 정보를 입력해 준다.
3. `Create` 버튼을 클릭한다.

> `Manually`로 프로젝트를 등록하더라도, 추후 저장소 연결은 가능하다.

`Create`버튼 클릭 후 표시되는 프로젝트 설정 화면에서 `Create build configuration` 버튼을 클릭하여 빌드 설정화면으로 진입힌다.
![Project 설정 화면](/assets/img/post/infra/teamcity/teamcity-deploy-setting/003.png)

### 빌드설정 등록
빌드 설정화면이 표시되면, 설정 정보를 입력해 준다. 프로젝트 설정과 마찬가지로, 소스를 연결 할 수 있지만, 설명을 위해 `Manually`를 선택했다.
소스를 연결 할 경우, 뒤에 설명 할 `Trigger` 설정 등이 자동 처리된다.
![Create Build Configuration](/assets/img/post/infra/teamcity/teamcity-deploy-setting/004.png)

이후 `New VCS Root` 화면이 표시되고, 소스를 연결 할 수 있도록 해주지만, 이 포스팅에서는 `Skip`버튼을 클릭하여 스킵하였다.

#### 트리거
이후 표시되는 설정 화면에서 먼저 `Triggers` 설정에 대해서 알아보도록 하겠다.
`Triggers` 설정은 빌드를 언제 실행 할 것인지에 대한 설정이다. 이 포스팅에서는 `VCS Trigger`와 `Finish Build Trigger`를 사용한다.
`VCS Trigger`는 소스 변경이 감지되면 실행하도록 설정하는 방법이고, `Finish Build Trigger`는 특정 빌드가 종료된 후 실행하도록 설정하는 방법이다.
프로젝트나 빌드 설정단계에서 VCS 연결한 경우 `VCS Trigger`가 자동으로 설정되어 있어서, 변경을 감지 할 브랜치 정보만 수정하여 그대로 사용하면 된다.
이 표스팅에서는 단순히 설명을 위한 예시이므로, 상세 설정은 생락한다.
간단히 Build/Push를 담당하는 설정에서는 `VCS Trigger`를 이용하여, 형상관리 서버의 특정 브랜치에 Push가 발생하면 실행이되고, 
배포를 담당하는 설정에서는 `Finish Build Trigger`를 이용하여, Build/Push를 담당하는 설정이 실행된 후 실행되도록 설정한다는 개념만 이해하도록 하겠다.
![Triggers](/assets/img/post/infra/teamcity/teamcity-deploy-setting/005.png)

#### 빌드 스텝
다음으로 `Build Steps` 메뉴를 클릭하고, `Add build step`버튼을 클릭한다.
![Build Steps](/assets/img/post/infra/teamcity/teamcity-deploy-setting/006.png)

이후 표시되는 `New Build Step`화면에서 미리 구성된 템플릿을 이용하여 빌드를 구성 할 수 있도록 제공해 준다.
각 템플릿들을 연구하여 추후 개선 할 수도 있지만, 현재로서는 `Command Line` 템플릿만 이용하여 빌드 절차를 구성하였다.
필수 절차와 샘플 스크립트를 공유하겠다. 먼저 화면에서 `Command Line`를 클릭하여 상세 설정화면으로 진입한다.
![New Build Step](/assets/img/post/infra/teamcity/teamcity-deploy-setting/007.png)

> 사내 프로젝트는 기본적으로 프로젝트 루트에 `.docker` 디렉토리에 `docker-compose.yml`에서 사용 할 환경 변수 파일들을 저장하고 있다.
> 또한 Back-end 프로젝트(Spring boot)의 경우 `resources`에 `application-secret.yml` 파일을 저장하고 있다.
> 환경 변수 파일 및 secret 파일에는 보안 설정(비밀번호 등)이 포함되어 있으므로, `.gitignore`에 등록하여 형상관리에서 제외하고 있다.
> 빌드 단계에서는 이 파일들이 필요 하므로, 빌드 단계는 대략적으로 1. 설정파일 복사 2. 도커 이미지로 빌드 3. 빌드된 이미지를 사내 저장소에 Push 하는 절차로 구성하였다.
> 각 단계 사이사이에 프로젝트 특성에 따라 추가 단계가 필요 할 수 있다.

먼저 설정파일을 복사하는 단계를 구성한다. Agent-001 환경 변수에는 각 프로젝트에서 빌드시 필요한 리소스를 저장하고 있는 경로가 `env.buildResourceDir`
환경 변수에 저장되어 있다. 이를 이용하여 빌드시 필요한 설정 파일들을 복사하도록 한다.
![New Build Step:Command Line](/assets/img/post/infra/teamcity/teamcity-deploy-setting/008.png)
1. 현재 스텝에서 작업 할 내용을 요약하여 `Step name`을 입력한다.
2. 작업 할 내용을 `Custom script`에 입력한다.
   ```shell
   echo "도커용 설정 파일 복사"
   cp -rf %env.buildResourceDir%/sample/.docker %teamcity.build.checkoutDir%/
   
   echo "보안 설정파일 복사"
   cp %env.buildResourceDir%/sample/backend/resources/application-secret.yml  %teamcity.build.checkoutDir%/backend/src/main/resources/
   ```
   * `%env.buildResourceDir%` : Agent-001 환경 변수에 저장된 빌드시 필요한 리소스 경로
   * `%teamcity.build.checkoutDir%` : 현재 빌드가 소스를 체크아웃한 경로 (프로젝트 루트)
3. `Save`버튼을 클릭하여 저장한다.

이후 스텝도 모두 Command Line 템플릿을 이용하여 진행하므로, 스크린샷 첨부는 생락한다. 아래 내용을 참고하여 2, 3 단계의 스텝을 추가한다.
* 도커 이미지 빌드 스텝
   1. Step name: 도커 이미지 빌드
   2. Custom script
      ```shell
      echo "프로젝트 루트 경로에서 작업"
      cd %teamcity.build.checkoutDir%
      
      echo "backend 도거 이미지 빌드"
      docker-compose --env-file=./.docker/dev.env build backend
      ```

* 빌드된 이미지를 사내 저장소에 Push 스텝
   1. Step name: 도커 이미지 사내 저장소 Push
   2. Custom script
      ```shell
      echo "푸시용 스크립트 파일 작업 경로로 이동"
      cd %env.buildResourceDir%/sample
      
      echo "Push 작업용 스크립트 실행"
      %env.buildResourceDir%/sample/docker-push.sh
      ```

`docker-push.sh` 스크립트는 사내 저장소 로그인 후 빌드된 도커 이미지 tag 및 Push를 수행하는 스크립트이다.
아래 샘플을 참고하여 각 프로젝트에 맞도록 수정하여, 프로젝트별 `buildResourceDir`에 저장한다.

***docker-push.sh***
```shell
#!/bin/bash

# 로그인 처리
password=$(cat /data/teamcity_agent/.docker/nexus3_key)
docker login -u teamcity -p $password repo.bud-it.com

# Get current date
yyyy=$(date +%Y)
mm=$(date +%m)
dd=$(date +%d)

# Get and increment build number
build_number=$(cat build_number.txt)
echo $((build_number+1)) > build_number.txt

# Get last pushed image ID
last_pushed_image_id=$(cat last_pushed_sample_image_id.txt)

# Initialize push flag
push_image=false

# Get docker images
images=$(docker images)

# Parse images and perform operations
while IFS= read -r line; do
    repository=$(echo $line | awk '{print $1}')
    tag=$(echo $line | awk '{print $2}')
    image_id=$(echo $line | awk '{print $3}')

    # Remove <none> images
    if [[ $repository == "<none>" && $tag == "<none>" ]]; then
        docker image rm $image_id
    fi

    # Tagging and pushing image
    if [[ $repository == *_sample && $tag == "latest" && $image_id != $last_pushed_image_id ]]; then
        docker tag $repository:$tag repo.bud-it.com/sample:latest
        docker tag $repository:$tag repo.bud-it.com/sample:v${yyyy}.${mm}.${dd}.${build_number}
        echo $image_id > last_pushed_sample_image_id.txt
        push_image=true
    fi
done <<< "$images"

# Push tagged images if any
if $push_image; then
    docker push repo.bud-it.com/sample:latest
    docker push repo.bud-it.com/sample:v${yyyy}.${mm}.${dd}.${build_number}
fi
```

여기까지 진행하면 아래 이미지와 같이 3개 스텝을 갖는 빌드 설정이 완성된다.
![Build Steps](/assets/img/post/infra/teamcity/teamcity-deploy-setting/009.png)

### Agent 할당
이후 생성한 빌드 설정을 실행 할 Agent를 지정해 주어야 한다.
신규 프로젝트 등록시 `Default` 그룹에는 프로젝트가 자동으로 추가되지만, 그외 그룹에는 아래 스크린샷을 참고하여 `Assign projects...`버튼을
활용하여 프로젝트를 추가해 주어야 한다.
![Assign projects](/assets/img/post/infra/teamcity/teamcity-deploy-setting/010.png)
1. 상단 메뉴의 `Agents` 메뉴를 클릭한다.
2. `Default` 그룹을 클릭한다.
3. `Projects` 탭을 클릭한다.
4. 추가된 프로젝트가 배정되어 있는지 확인하고, 배정되어 있지 않다면 `Assign projects...`버튼을 클릭하여 프로젝트를 배정한다.
   * `Docker`를 이용하여 기동된 빌드 담당(리소스를 많이 소요하는 역할을 담당 할 용도)의 Agent는 `Default` 그룹을 사용한다.
   * 각 개발 서버에 Standalone으로 설치된 배포 담당의 Agent는 `Develop-server` 그룹을 사용한다.

이제 빌드 할 Agent에 위에서 작성한 빌드설정을 할당해보도록 하겠다.
참고로 한 프로젝트의 빌드 설정을 빌드용 설정과 배포용 설정으로 구분하여 각각 담당하는 Agent를 구분하므로, 할당 방식을 `Run assigned configurations only`로 설정하여 사용하고 있다.
(아래 스크린샷의 중간부분 2와 3 사이의 설정을 참고한다.)
![Agent 설정](/assets/img/post/infra/teamcity/teamcity-deploy-setting/011.png)
1. 빌드 설정을 할당 할 `Agent-001` Agent를 클릭한다.
2. `Compatible Configurations` 탭을 클릭한다.
3. `Assign configurations` 버튼을 클릭한다.
4. 할당 할 빌드설정의 체크박스를 체크한다.
5. `Assign`버튼을 클릭하여 할당한다.

### 배표용 빌드설정 등록
이후 배포용 설정은 위 빌드용 설정과 유사하므로 차이점과 샘플로 사용 할 `Custom script` 내용 정도만 설명하겠다.
먼저 설정의 `Triggers`는 위 설명을 참고하여 `Finish Build Trigger`를 설정한다. 프로젝트나 빌드설정 추가 단계에서, VCS가 연결되었다면,
기본적으로 `VCS Trigger`가 설정되어 있으므로, 우측 `Edit` 오른펀의 버튼을 클릭하여 삭제하고, `Finish Build Trigger`만 추가하면 된다.
![Triggers](/assets/img/post/infra/teamcity/teamcity-deploy-setting/012.png)
앞에서 설정한 빌드용 설정이 성공한 후에 배포용 설정이 실행되도록 설정하는 예시이다. 선행되어 실행되어야 할 설정을 선택해 주고,
`Trigger after successful build only` 설정을 체크하면 선행 설정이 성공했을때만 실행되고, 체크하지 않으면 성공/실패와 무관하게 실행된다.

다음으로 `Build Steps` 메뉴로 이동하여 각 빌드 스텝을 추가한다.
1. 도커 이미지 저장소에 로그인
   ```shell
   cat ~/.docker/private_repo_key | docker login --username teamcity --password-stdin repo.bud-it.com
   ```
   
2. 도커 컴포즈 실행
   ```shell
   cd %env.project.sample.dockerDir%
   
   docker-compose down
   docker image rm repo.bud-it.com/sample:latest
   docker-compose build
   docker-compose up -d
   ```
   * `%env.project.sample.dockerDir%`: 각 프로젝트 별로 배포용 `docker-compose.yml` 파일이 저장된 경로를 환경변수로 관리하고 있다.
   * `docker-compose` 명령을 이용하여 컨테이너를 정지하고, 기존 이미지를 삭제 후 빌드/기동 절차를 진행하도록 구성한다.
   
여기까지 진행하면 각 프로젝트에서 공통으로 처리하는 절차의 설명은 완료되었다.
이 외 각 프로젝트 특성별로 추가 절차들은 프로젝트 성격에 맞게 수정해서 반영해 나간다.

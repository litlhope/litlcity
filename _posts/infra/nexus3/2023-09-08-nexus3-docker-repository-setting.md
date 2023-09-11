---
layout: post
title: Nexus3에 사내 도커 저장소 생성
date: 2023-09-08 10:02
description: 사내 Nexus3에서 도커 저장소를 생성하는 방법에 대해서 기술 한다.
comments: true
categories: [Infra, Nexus3]
tags: [Nexus3, Docker, Docker Hub, Infra, Setting]
---

## Nexus3에 사내 도커 저장소 생성
> 사내 Nexus3(https://nexus3.bud-it.com)에 도커 저장소를 생성하는 방법에 대해서 기술 한다.

### 1. Blob Stores 생성
> `docker-hosted`와 `docker-proxy` 두개의 Blob Stores를 생성한다.

1. `Blob Stores` 메뉴로 이동한다.
   ![Blob Stores 메뉴로 이동](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/001.png)
   1. 상단 톱니바퀴를 클릭하여 관리 페이지에 진입한다.
   2. 왼쪽 메뉴에서 `Repository > Blob Stores`를 클릭한다.
   3. 상단의 `Create blob store` 버튼을 클릭한다.
   
2. `docker-hosted` 정보를 입력한다.
   ![docker-hosted 정보 설정](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/002.png)
   1. `Type`을 `File`로 선택하면, 하단 입력 폼이 표시된다.
   2. `Name`에 `docker-hosted`를 입력한다.
      - 이때 `Path`는 자동으로 입력된다.
   3. `Save` 버튼을 클릭한다.
   4. 저장 후 목록 화면으로 이동한다. 목록에 `docker-hosted`가 추가된 것을 확인 할 수 있다.
   5. 상단의 `Create blob store` 버튼을 클릭한다.
   
3. `docker-proxy` 정보를 입력한다.
   ![docker-proxy 정보 설정](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/003.png)
   1. `Type`을 `File`로 선택하면, 하단 입력 폼이 표시된다.
   2. `Name`에 `docker-proxy`를 입력한다.
      - 이때 `Path`는 자동으로 입력된다.
   3. `Save` 버튼을 클릭한다.

### 2. Repositories 생성
> `docker-hosted`와 `docker-proxy` 두개의 Repositories를 생성한다.

1. `Repositories` 메뉴로 이동한다.
   ![Repositories 메뉴로 이동](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/004.png)
   1. 관리 페이지에서 `Repository > Repositories`를 클릭한다.
   2. 상단의 `Create repository` 버튼을 클릭한다.

2. `Recipe`중 `docker(hosted)` 항목을 선택한다.
   ![docker(hosted) 선택](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/005.png)

3. `docker-hosted` 정보를 입력한다.
   ![docker-hosted 정보 설정](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/006-1.png)
   1. `Name`에 `docker-hosted`를 입력한다.
   2. `HTTP` 체크박스를 체크하고, 포트를 `5000`으로 입력한다.
   3. `Enable Docker V1 API` 체크박스를 체크한다.
   ![docker-hosted 정보 설정](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/006-2.png)
   4. `Blob store`에 `docker-hosted`를 선택한다.
   ![docker-hosted 정보 설정](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/006-3.png)
   5. `Create repository` 버튼을 클릭한다.

4. `Recipe`중 `docker(proxy)` 항목을 선택한다.
   ![docker(proxy) 선택](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/007.png)

5. `docker-proxy` 정보를 입력한다.
   ![docker-proxy 정보 설정](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/008-1.png)
   1. `Name`에 `docker-proxy`를 입력한다.
   2. `Enable Docker V1 API` 체크박스를 체크한다.
   ![docker-proxy 정보 설정](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/008-2.png)
   3. `Remote Storage`에 `https://registry-1.docker.io`를 입력한다.
   4. `Docker Index` 선택 항목 중 `Use Docker Hub`를 선택한다.
   ![docker-proxy 정보 설정](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/008-3.png)
   5. `Blob store`에 `docker-proxy`를 선택한다.
   6. `Create repository` 버튼을 클릭한다.

### 3. Realms 설정
> `docker-proxy`를 사용하기 위해서는 `Realms` 설정이 필요하다.

![Realms 설정](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/009-1.png)
1. 관리 페이지에서 `Security > Realms`를 클릭한다.
2. Available 항목의 `Docker Bearer Token Realm`을 클릭한다.
   * 클릭시 `Docker Bearer Token Realm`이 `Active` 항목으로 이동한다.
![Realms 설정](/assets/img/post/infra/nexus3/nexus3-docker-repository-setting/009-2.png)
3. `Save` 버튼을 클릭한다.

여기까지 진행하면 `Nexus3`쪽 설정은 완료되었다.
이후 설명 할 내용은 `Nexus3`와 무관하며, 위와 같이 설정된 사내 Docker 저장소를 이용하는데 필요한 `docker` 명령어 예시이다.
아래 내용을 참고하여 각자 필요한 형태로 수정하여 사용 하도록 한다.

### 4. docker 명령어 예시
> 위에 설정한 `Nexus3`의 저장소 설정시 사용한 5000번 포트는 `repo.bud-it.com`도메인으로 접근하도록 설정 완료한 상태이다.(2023년 9월 11일 기준)
> 따라서 아래 예시에서는 `repo.bud-it.com`을 사용하도록 한다.

1. `docker` 저장소에 로그인.
   1. 기본적인 로그인 방법.
      ```shell
      $ docker login --username <username> --password <password> repo.bud-it.com
      ```
   2. `~/.docker/nexus3-pw` 파일에 패스워드를 저장하여 로그인 하는 방법
      > 명령줄에서 패스워드를 노출하여 사용 할 경우, `history` 명령등을 이용하여 패스워드가 노출 될 수 있으므로, 별도 파일로 저장하여 사용하는 것이 좋다.
      ```shell
      $ echo <password> > ~/.docker/nexus3-pw
      $ cat ~/.docker/nexus3-pw | docker login --username <username> --password-stdin repo.bud-it.com
      ```

2. `tag` 명령어를 이용하여 repository 지정
   > `sample-project`라는 이미지가 있다고 가정하고, `repo.bud-it.com/sample-project`로 저장소를 지정 하고자 한다면 다음 명령을 사용 할 수 있다.
   ```shell
   $ docker tag sample-project:latest repo.bud-it.com/sample-project:latest
   ```
   * 뒤의 `latest` 부분은 태그를 의미하며, 필요에 따라 변경하여 사용하면 된다.

3. `push` 명령을 이용하여 저장소에 이미지를 업로드 한다.
   ```shell
   $ docker push repo.bud-it.com/sample-project:latest
   ```

이후 `pull`명려 또는 `run`명령에서 `repo.bud-it.com/sample-project:latest`를 사용하여 저장소의 이미지를 사용 할 수 있다.
사내 표준에 의해 `docker-compose`를 사용 하므로, 컨테이너 설정의 `image`에서 `repo.bud-it.com/sample-project:latest`를 사용하도록 한다.

### 참고
사내 시스템에서는 `repo.bud-it.com` 도메인을 이용하여 `https`로 접근하도록 설정된 상태이므로,
아래 소개한 설정이 생략되어 있으나, 그렇지 않은 경우 `login`시 오류가 발생한다고 한다. 그럴 경우 서버 및 클라이언트에서 아래 설정이 추가되어야
한다고 한다. IP를 직접 사용하는 케이스는 대응 하지 않을 예정이므로, 아래 내용은 참고 용도로만 알고 있으면 될 듯 하다.

`/etc/docker/daemon.json` 파일에 아래 내용을 추가한다. 이 파일은 기본적으로 존재하지 않으므로, 없을 경우 생성하도록 한다.

***daemon.json***
```json
{
	"insecure-registries" : ["192.168.xxx.xxx:5000"]
}
```

파일 추가/수정 후에는 `docker` 서비스를 재시작한다.
```shell
$ sudo service docker restart
$ docker-compose restart
Restarting nexus3 ... done
```

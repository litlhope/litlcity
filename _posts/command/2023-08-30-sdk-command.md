---
layout: post
title: sdkman을 이용하여 SDK 관리하기
date: 2023-08-30 13:11
description: sdkman의 sdk 명령 설치 및 사용 방법에 대해 정리 한다.
comments: true
categories: [ Command ]
tags: [ CLI, Command, sdk, sdkman ]
---

## 시작하며...
Java 벤더가 여러개이고, 프로젝트 마다 사용하는 버전이 제각각인 상황에서, `brew`를 이용하여 SDK를 관리하고, `jenv` 등의 방법을 이용하여 관리하였다.
그러던 중 `Spring Boot Up & Running`책을 통해 SDKMAN을 알게 되어, 설치하여 상용해 보고 있는 중이다.
설치 방법 및 이용 방법에 대해 정리하고자 한다.

### `sdkman`이란?
1. `sdkman`은 `Java`, `Scala`, `Groovy`, `Kotlin` 등의 SDK를 관리하는 오픈소스 도구이다.
2. `brew`와 유사하게 `sdk` 명령어를 이용하여 SDK를 설치/관리 할 수 있다.
3. 공식 사이트 : https://sdkman.io

## 환경
1. macOS Ventura 13.5

## 명령어
### 설치
공식사이트 첫화면에 있는 명령어를 이용하여 설치 할 수 있다. 명령을 실행하면, 텍스트 이미지로 큰 SDK! 글자가 출력되며, 설치가 진행된다.

```shell
$ curl -s "https://get.sdkman.io" | bash

                                -+syyyyyyys:
                            `/yho:`       -yd.
                         `/yh/`             +m.
                       .oho.                 hy                          .`
                     .sh/`                   :N`                `-/o`  `+dyyo:.
                   .yh:`                     `M-          `-/osysoym  :hs` `-+sys:      hhyssssssssy+
                 .sh:`                       `N:          ms/-``  yy.yh-      -hy.    `.N-````````+N.
               `od/`                         `N-       -/oM-      ddd+`     `sd:     hNNm        -N:
              :do`                           .M.       dMMM-     `ms.      /d+`     `NMMs       `do
            .yy-                             :N`    ```mMMM.      -      -hy.       /MMM:       yh
          `+d+`           `:/oo/`       `-/osyh/ossssssdNMM`           .sh:         yMMN`      /m.
         -dh-           :ymNMMMMy  `-/shmNm-`:N/-.``   `.sN            /N-         `NMMy      .m/
       `oNs`          -hysosmMMMMydmNmds+-.:ohm           :             sd`        :MMM/      yy
      .hN+           /d:    -MMMmhs/-.`   .MMMh   .ss+-                 `yy`       sMMN`     :N.
     :mN/           `N/     `o/-`         :MMMo   +MMMN-         .`      `ds       mMMh      do
    /NN/            `N+....--:/+oooosooo+:sMMM:   hMMMM:        `my       .m+     -MMM+     :N.
   /NMo              -+ooooo+/:-....`...:+hNMN.  `NMMMd`        .MM/       -m:    oMMN.     hs
  -NMd`                                    :mm   -MMMm- .s/     -MMm.       /m-   mMMd     -N.
 `mMM/                                      .-   /MMh. -dMo     -MMMy        od. .MMMs..---yh
 +MMM.                                           sNo`.sNMM+     :MMMM/        sh`+MMMNmNm+++-
 mMMM-                                           /--ohmMMM+     :MMMMm.       `hyymmmdddo
 MMMMh.                  ````                  `-+yy/`yMMM/     :MMMMMy       -sm:.``..-:-.`
 dMMMMmo-.``````..-:/osyhddddho.           `+shdh+.   hMMM:     :MmMMMM/   ./yy/` `:sys+/+sh/
 .dMMMMMMmdddddmmNMMMNNNNNMMMMMs           sNdo-      dMMM-  `-/yd/MMMMm-:sy+.   :hs-      /N`
  `/ymNNNNNNNmmdys+/::----/dMMm:          +m-         mMMM+ohmo/.` sMMMMdo-    .om:       `sh
     `.-----+/.`       `.-+hh/`         `od.          NMMNmds/     `mmy:`     +mMy      `:yy.
           /moyso+//+ossso:.           .yy`          `dy+:`         ..       :MMMN+---/oys:
         /+m:  `.-:::-`               /d+                                    +MMMMMMMNh:`
        +MN/                        -yh.                                     `+hddhy+.
       /MM+                       .sh:
      :NMo                      -sh/
     -NMs                    `/yy:
    .NMy                  `:sh+.
   `mMm`               ./yds-
  `dMMMmyo:-.````.-:oymNy:`
  +NMMMMMMMMMMMMMMMMms:`
    -+shmNMMMNmdy+:`


                                                                 Now attempting installation...


Looking for a previous installation of SDKMAN...

...

All done!


You are subscribed to the STABLE channel.

Please open a new terminal, or run the following in the existing one:

    source "/Users/xxxxx/.sdkman/bin/sdkman-init.sh"

Then issue the following command:

    sdk help

Enjoy!!!
```

설치가 완료되면 마지막 부분에 `source "/Users/xxxxx/.sdkman/bin/sdkman-init.sh"` 명령어를 실행하라고 안내한다. 실행해 주자.
(xxxxx)부분은 자신의 계정명이다.
```shell
$ source "/Users/xxxxx/.sdkman/bin/sdkman-init.sh"
```

여기까지 진행하면 `sdk` 명령어를 사용 할 수 있다.

### 설치 가능한 Java 목록 확인
> `sdk` 명령은 `Gradle`, `Kotlin` 등 다양한 SDK를 관리 할 수 있지만, 여기서는 `Java` 관리만을 예시로 설명 하고자 한다.

```shell
$ sdk list java
================================================================================
Available Java Versions for macOS ARM 64bit
================================================================================
 Vendor        | Use | Version      | Dist    | Status     | Identifier
--------------------------------------------------------------------------------
 Corretto      |     | 20.0.2       | amzn    |            | 20.0.2-amzn
               |     | 20.0.1       | amzn    |            | 20.0.1-amzn
               |     | 17.0.8       | amzn    |            | 17.0.8-amzn
               |     | 17.0.7       | amzn    |            | 17.0.7-amzn
               |     | 11.0.20      | amzn    |            | 11.0.20-amzn
               |     | 11.0.19      | amzn    |            | 11.0.19-amzn
               |     | 8.0.382      | amzn    |            | 8.0.382-amzn
               |     | 8.0.372      | amzn    |            | 8.0.372-amzn
 Gluon         |     | 22.1.0.1.r17 | gln     |            | 22.1.0.1.r17-gln
               |     | 22.1.0.1.r11 | gln     |            | 22.1.0.1.r11-gln
 GraalVM CE    |     | 20.0.2       | graalce |            | 20.0.2-graalce
               |     | 20.0.1       | graalce |            | 20.0.1-graalce
               |     | 17.0.8       | graalce |            | 17.0.8-graalce
               |     | 17.0.7       | graalce |            | 17.0.7-graalce
 GraalVM Oracle|     | 20.0.2       | graal   |            | 20.0.2-graal
               |     | 20.0.1       | graal   |            | 20.0.1-graal
               |     | 17.0.8       | graal   |            | 17.0.8-graal
               |     | 17.0.7       | graal   |            | 17.0.7-graal
 Java.net      |     | 22.ea.12     | open    |            | 22.ea.12-open
               |     | 22.ea.11     | open    |            | 22.ea.11-open
               |     | 22.ea.10     | open    |            | 22.ea.10-open
               |     | 22.ea.9      | open    |            | 22.ea.9-open
               |     | 22.ea.8      | open    |            | 22.ea.8-open
               |     | 22.ea.7      | open    |            | 22.ea.7-open
               |     | 22.ea.6      | open    |            | 22.ea.6-open
               |     | 22.ea.5      | open    |            | 22.ea.5-open
:
```
위와 같이 설치 가능한 벤더별 `Java` 목록을 확인 할 수 있다.
스페이스키를 눌러 페이지 단위로 다음 목록을 확인 할 수 있다. 목록의 내용 중 `Identifier` 부분을 보면, 설치시 사용 할 수 있는 식별자를 확인 할 수 있다.
예를 들어 아마존(벤더명 `Corretto`)의 `Java 11.0.20`을 설치하고 싶다면, 해당하는 식별자 `11.0.20-amzn`을 사용하면 된다.

### Java 설치
목록을 확인하여 설치하고자 하는 `Java`의 식별자를 확인하였다면, `sdk install` 명령어를 이용하여 설치 할 수 있다.

```shell
$ sdk install java 11.0.20-amzn
Downloading: java 11.0.20-amzn

In progress...
######################################################################## 100.0%

...
```

> `sdk` 명령을 이용하여 최초로 설치했다면 설치한 버전이 default로 설정된다.

### 설치된 Java 목록 확인
```shell
$ sdk list java
================================================================================
Available Java Versions for macOS ARM 64bit
================================================================================
 Vendor        | Use | Version      | Dist    | Status     | Identifier
--------------------------------------------------------------------------------
  Corretto      |     | 20.0.2       | amzn    |            | 20.0.2-amzn
                |     | 20.0.1       | amzn    |            | 20.0.1-amzn
                |     | 17.0.8       | amzn    |            | 17.0.8-amzn
                |     | 17.0.7       | amzn    |            | 17.0.7-amzn
                | >>> | 11.0.20      | amzn    | installed  | 11.0.20-amzn
                |     | 11.0.19      | amzn    |            | 11.0.19-amzn
                |     | 8.0.382      | amzn    |            | 8.0.382-amzn
                |     | 8.0.372      | amzn    |            | 8.0.372-amzn
  Gluon         |     |

...
```

`Status`에 `installed`로 표시되는 버전이 현재 설치된 자바 버전이고, `Use`에 `>>>`로 표시되는 버전이 현재 사용중인 버전이다.

### 설치된 Java 버전 변경
```shell
$ sdk use java 11.0.20-amzn
Using java version 11.0.20-amzn in this shell.
```
`use` 명령을 이용하여, 사용할 버전을 변경 할 수 있다.
이때, 시스템을 재기동 하면, 이전에 사용중이던 버전으로 되돌아간다.

### 시스템 기본 Java 버전 변경
```shell
$ sdk default java 11.0.20-amzn
Default java version set to 11.0.20-amzn
```
`default` 명령을 이용하여, 시스템 기본 버전을 변경 할 수 있다. 기본 버전을 변경하면, 시스템이 재기동 되더라도 변경된 버전으로 유지된다.

---
layout: post
title: 웹 소켓 개발 가이드(in BUD-IT)
date: 2023-08-12 10:55
description: 사내 웹 소켓 개발시 개발 가이드를 정리 한다.
comments: true
categories: [WebSocket]
tags: [WebSocket, Develop Guide, Code Convention, Spring Boot]
---

## 목차
[개발 가이드](#개발-가이드)
* [1. 개발 환경](#1-개발-환경)
* [2. 프로토콜](#2-프로토콜)
   * [2.1. 클라이언트 -> 서버 프로토콜](#21-클라이언트--서버-프로토콜)
   * [2.2 서버 -> 클라이언트 프로토콜 and 브로드 캐스팅 프로토콜](#22-서버--클라이언트-프로토콜-and-브로드-캐스팅-프로토콜)
   * [2.3. 커맨드 작성 규칙](#23-커맨드-작성-규칙)
* [3. 개발 가이드](#3-개발-가이드)
   * [3.1. 서버](#31-서버)
      * [3.1.1. 주요 클래스](#311-주요-클래스)
      * [3.1.2 주요 공용 메서드](#312-주요-공용-메서드)
   * [3.2 서버 서비스 구현 절차 - 채팅 서비스 예시](#32-서버-서비스-구현-절차---채팅-서비스-예시)
      * [3.2.1. 서비스용 패키지 추가](#321-서비스용-패키지-추가)
      * [3.2.2. EndPoint 클래스 작성](#322-endpoint-클래스-작성)
      * [3.2.3. `SocketClient` 클래스 작성](#323-socketclient-클래스-작성)
      * [3.2.4. `SocketClientPool` 클래스 작성](#324-socketclientpool-클래스-작성)
      * [3.2.5. 소켓 프로토콜 정의서 확인 및 구현](#325-소켓-프로토콜-정의서-확인-및-구현)
   * [3.3 클라이언트](#33-클라이언트)
      * [3.3.1. 필요 라이브러리 설치](#331-필요-라이브러리-설치)
      * [3.3.2. `WebSocket` 관리를 위한 `recoil` 상태 추가](#332-websocket-관리를-위한-recoil-상태-추가)
      * [3.3.3. 서비스 진입점 작성 및 `WebSocket` 연결 처리](#333-서비스-진입점-작성-및-websocket-연결-처리)
      * [3.3.4. 서비스 화면 개발 예시](#334-서비스-화면-개발-예시)

## 개발 가이드
### 1. 개발 환경
* Java 17
* Spring Boot 3.1.2
* Gradle 8.2.1
* Spring Boot Dependencies
   ```groovy
   // LocalDateTime support for Jackson
   implementation 'com.fasterxml.jackson.datatype:jackson-datatype-jsr310'
  
   implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
   implementation 'org.springframework.boot:spring-boot-starter-web'
   implementation 'org.springframework.boot:spring-boot-starter-websocket'
   compileOnly 'org.projectlombok:lombok'
   developmentOnly 'org.springframework.boot:spring-boot-devtools'
   developmentOnly 'org.springframework.boot:spring-boot-docker-compose'
   runtimeOnly 'org.mariadb.jdbc:mariadb-java-client'
   annotationProcessor 'org.projectlombok:lombok'
   testImplementation 'org.springframework.boot:spring-boot-starter-test'
   ```
   * `org.springframework.boot:spring-boot-starter-websocket` : WebSocket 지원
  
### 2. 프로토콜
> 통신은 기본적으로 JSON을 이용하여 데이터를 주고 받는다.

#### 2.1. 클라이언트 -> 서버 프로토콜
> 커맨드와 데이터를 `::`로 구분하고, 커맨드는 일반 문자열(영문 대문자 스네이크 케이스)을 사용하고,
> 데이터는 JSON 형식으로 전달한다.

*예시*
```
CS_GET_ROOM::{"roomId": 1}
```

#### 2.2 서버 -> 클라이언트 프로토콜 and 브로드 캐스팅 프로토콜
> 서버에서 클라이언트로 전달하는 프로토콜은 JSON 형식으로 전달한다.

*예시*
```
{"command": "SC_GET_ROOM", "code": 200, "message": "OK", "data": {"roomId": 1}}
```
1. `command`
   * 클라이언트로 전달 할 커맨드이다.
   * 커맨드를 기준으로 작동 함수를 호출한다.
2. `code`
   * 커맨드 수행 결과 응답 코드이다.
3. `message`
   * 커맨드 수행 결과 응답 메시지이다.
4. `data`
   * 클라이언트 요청 커맨드에 대한 응답 데이터이다.

#### 2.3. 커맨드 작성 규칙
1. 커맨드는 영문 대문자 스네이크 케이스를 사용한다.
2. 커맨드는 prefix로 `CS_`, `SC_`, `BC_`를 사용한다.
   * `CS_` : 클라이언트 -> 서버
   * `SC_` : 서버 -> 클라이언트
   * `BC_` : 브로드 캐스팅
3. Prefix 이후 커맨드는 동사로 시작한다. 주요 동사는 다음 예제를 참고하고, 예시 외에도 필요시 정의하여 사용 할 수 있다.
   * `GET_` : 조회
   * `SET_` : 설정 또는 저장
   * `REG_` : 신규 데이터 등록
   * `UPD_` : 데이터 수정
   * `DEL_` : 데이터 삭제
   * `RES_` : 요청에 대한 처리 결과 응답
4. `BC_` 커맨드의 경우 위 3번 규칙을 무시 할 수 있다.
5. 이 후 커맨드 이름을 명시적으로 작성한다. 몇가지 예를 들면 다음과 같다.
   * `CS_GET_ROOM` : 클라이언트가 룸 정보를 조회 한다.
   * `SC_RES_GET_ROOM` : 클라이언트의 `GET_ROOM` 명령 요청에 대해 룸 정보를 응답 한다.
   * `BC_ROOM` : 신규 작성 또는 수정된 룸 정보를 브로드 캐스팅 한다.

### 3. 개발 가이드
#### 3.1. 서버
##### 3.1.1. 주요 클래스
> 프로젝트 루트 패키지에 `socket` 패키지를 생성하여 관련 클래스를 작성한다.
> 이후 각 서비스별로 패키지를 추가(아래 예시에서는 `chat`)하여 관련 클래스를 상속/구현하여 사용한다.

```shell
❯ tree ./socket
./socket
├── SocketClient.java
├── SocketClientPool.java
├── SocketCommand.java
├── SocketListener.java
├── SocketService.java
└── chat
    ├── ChatSocketClient.java
    ├── ChatSocketClientPool.java
    ├── ChatSocketController.java
    ├── client
    │   ├── ChatClientSocketService.java
    │   └── dto
    │       ├── BcOnlineDto.java
    │       ├── CsGetClientDto.java
    │       └── ScResClientDto.java
    ├── message
    │   ├── ChatMessageSocketService.java
    │   └── dto
    │       ├── BcMessageDto.java
    │       └── CsSendMessageDto.java
    ├── room
    │   ├── ChatRoomSocketService.java
    │   └── dto
    │       ├── CsGetRoomDto.java
    │       ├── CsJoinRoomDto.java
    │       ├── CsRegRoomDto.java
    │       ├── ScResRegRoomDto.java
    │       ├── ScResRoomDto.java
    │       └── ScResRoomUserDto.java
    └── user
        ├── ChatUserSocketService.java
        └── dto
            ├── CsGetFriendDto.java
            └── ScResFriendDto.java

10 directories, 25 files
```
1. `SocketClient.java`
   * 클라이언트 정보를 담는 클래스이다.
   * `SocketClientPool`에 등록된다.

2. `SocketClientPool.java`
   * 클라이언트 정보를 관리하는 클래스이다.
   * `SocketClient`를 등록/삭제/조회 하는 메소드를 제공한다.

3. `SocketCommand.java`
   * 커맨드를 정의하는 클래스이다.

4. `SocketListener.java`
   * `@ServerEndpoint` 어노테이션을 사용하여 웹 소켓 서버를 구현하는 클래스에서 이벤트 리스트로 등록 할 수 있도록 서비스 클래스에서 구현 해야 하는 `interface`이다.
   
5. `SocketService.java`
   * 각 소켓 서비스의 하위 서비스에서 소켓 메시지를 처리 하는 클래스에서 상속 받아 사용하는 클래스이다.

##### 3.1.2 주요 공용 메서드
1. `abstract SocketClientPool.java`
   1. 멤버 메서드
      > 아래 설명에서 `T`는 `T extends SocketClient`로 선언 됨.
      1. `protected  void addSocketClient(T socketClient)`
         * `SocketClientPool`에 `SocketClient`를 등록한다.
      2. `public T getSocketClient(Session session)`
         * `SocketClientPool`에 등록된 `SocketClient`를 조회한다.
         * `jakarta.websocket.Session`을 이용하여 조회한다.
      3. `public T getSocketClient(String uuid)`
         * `SocketClientPool`에 등록된 `SocketClient`를 조회한다.
         * `uuid`를 이용하여 조회한다.
      4. `public Session getSession(String uuid)`
         * `SocketClientPool`에 등록된 `SocketClient`의 `Session`을 조회한다.
         * `uuid`를 이용하여 조회한다.
   2. 추상 메서드
      1. `public abstract void addSocketClient(Session session, String uuid, Object... args);`
         * 상속 받는 각 서비스에서 구현해야 하며, 각 서비스별 SocketClient를 생성하여 멤버 메서드 `addSocketClient(T socketClient)`를 호출하도록 구현한다.
   
2. `abstract SocketService.java`
   1. 멤버 메서드
      1. `protected void send(SocketCommand<?> command, Session session)`
         * `Session`에 `SocketCommand`를 전송한다.
      2. `protected void broadcastAll(SocketCommand<?> command)`
         * `SocketClientPool`에 등록된 모든 `SocketClient`에 `SocketCommand`를 전송한다.
      3. `protected void broadcast(SocketCommand<?> command, List<String> uuidList)`
         * `SocketClientPool`에 등록된 `SocketClient` 중 `uuidList`에 포함된 `uuid`를 갖는 `SocketClient`에 `SocketCommand`를 전송한다.
      4. `protected String getCommand(String message)`
         * 클라이언트로 부터 수신한 `message`에서 커맨드를 추출하여 반환한다.
      5. `protected <T> T getData(String message, Class<T> clazz)`
         * 클라이언트로 부터 수신한 `message`에서 데이터를 추출하여 `clazz` 타입으로 반환한다.
      6. `protected String getDataString(String message)`
         * 클라이언트로 부터 수신한 `message`에서 데이터를 추출하여 `String` 타입(JSON String)으로 반환한다.
   2. 추상 메서드
      > 없음

#### 3.2 서버 서비스 구현 절차 - 채팅 서비스 예시
##### 3.2.1. 서비스용 패키지 추가
> `socket` 패키지 하위에 서비스용 패키지를 추가한다.

1. `socket` 패키지 하위에 서비스용 `chat` 패키지를 추가한다.

##### 3.2.2. EndPoint 클래스 작성
> `SocketController`를 suffix로 사용한다.
> 
> *MVC 패턴 개발 절차와 비슷하게 할 생각이었으나, `EndPoint` suffix를 사용하는것이 좀 더 명확 할 것 같기도 하다. 어떤 방향이 좋을지에 대해 논의해 보자.*

*ChatSocketController.java*
```java
@Slf4j
@Service
@ServerEndpoint(value = "/ws/chat")
public class ChatSocketController {
    private static final List<SocketListener> socketListenerList = new ArrayList<>();

    @OnOpen
    public void onOpen(Session session) {
        socketListenerList.forEach(socketListener -> socketListener.onOpen(session));
    }

    @OnMessage
    public void onMessage(String message, Session session) {
        socketListenerList.forEach(socketListener -> socketListener.onMessage(message, session));
    }

    @OnClose
    public void onClose(Session session) {
        socketListenerList.forEach(socketListener -> socketListener.onClose(session));
    }

    public static void addSocketListener(SocketListener socketListener) {
        socketListenerList.add(socketListener);
    }
}
```
1. `@ServerEndpoint(value = "/ws/chat")`
   * 웹 소켓 서버를 구현하는 클래스임을 선언한다.
   * `value`는 웹 소켓 서버의 URL을 지정한다.
2. EndPoint 개발 방법에 맞도록 `@OnOpen`, `@OnMessage`, `@OnClose`어노테이션 및 메소드를 추가한다.
   * `@OnOpen` : 클라이언트가 서버에 연결되면 호출된다.
   * `@OnMessage` : 클라이언트가 서버에 메시지를 전송하면 호출된다.
   * `@OnClose` : 클라이언트가 서버와 연결을 종료하면 호출된다.
3. 소켓 리스너 처리용 `static` 멤버 변수 및 멤버 메소드를 추가한다.
   * 소켓 리스너를 리스트로 저장하기 위한 멤버변수를 추가한다.
   ```java
   private static final List<SocketListener> socketListenerList = new ArrayList<>();
   ```
   * 소켓 리스너를 리스트에 추가하기 위한 멤버 메소드를 추가한다.
   ```java
   public static void addSocketListener(SocketListener socketListener) {
       socketListenerList.add(socketListener);
   }
   ```
4. `@OnOpen`, `@OnMessage`, `@OnClose` 메소드에서 `socketListenerList`에 등록된 `SocketListener`를 호출하도록 내용을 추가한다.

   *SocketListener.java*
   ```java
   public interface SocketListener {
       void onOpen(Session session);
       void onMessage(String message, Session session);
       void onClose(Session session);
   }
   ```
   * `EndPoint`의 각 `@OnOpen`, `@OnMessage`, `@OnClose` 메소드에서 각 메소드와 매치되는 Listener의 메소도를 호출하도록 구성한다.

##### 3.2.3. `SocketClient` 클래스 작성
> `SocketClient` 클래스를 상속받아 각 서비스별로 필요한 Properties를 추가하여 구현한다.
> 채팅서비스에서는 클라이언트의 `사용자ID`와 사용자가 현재 참여하고 있는 채팅방의 `roomId`를 추가하여 구성하였다.

*ChatSocketClient.java*
```java
@Getter
@Setter
public class ChatSocketClient extends SocketClient {
    private final Long userId;
    private Long roomId;

    public ChatSocketClient(Session session, String uuid, Long userId) {
        super(session, uuid);
        this.userId = userId;
    }
}
```
* `userId`는 불변이므로 `final`로 구성하였다.
* `roomId`는 사용자가 채팅방에 참여하면서 변경될 수 있으므로 `setter`를 추가하였다.

##### 3.2.4. `SocketClientPool` 클래스 작성
> `SocketClientPool` 클래스를 상속받아 위 [3.2.3. SocketClient 클래스 작성](#323-socketclient-클래스-작성)에서 작성한
> `ChatSocketClient`를 관리하도록 구현한다.
> 
> 주로 `ChatSocketClient`클래스에서 추가된 Properties를 관리하는 메소드를 추가하는 작업이 주를 이룬다.

*ChatSocketClientPool.java*
```java
@Component
public class ChatSocketClientPool extends SocketClientPool<ChatSocketClient> {
    @Override
    public void addSocketClient(Session session, String uuid, Object... args) {
        ChatSocketClient chatSocketClient = new ChatSocketClient(session, uuid, (Long) args[0]);
        addSocketClient(chatSocketClient);
    }

    public boolean isExistUser(Long userId) {
        return getSocketClientList().stream()
                .anyMatch(chatSocketClient -> chatSocketClient.getUserId().equals(userId));
    }

    public void setJoinRoom(Long userId, Long roomId) {
        getSocketClientList().stream()
                .filter(chatSocketClient -> chatSocketClient.getUserId().equals(userId))
                .forEach(chatSocketClient -> chatSocketClient.setRoomId(roomId));
    }

    public List<String> getRoomUserClientIdList(Long roomId) {
        return getSocketClientList().stream()
                .filter(chatSocketClient -> chatSocketClient.getRoomId() != null
                        && chatSocketClient.getRoomId().equals(roomId))
                .map(ChatSocketClient::getUuid)
                .toList();
    }
}
```
1. 부모 클래스의 추상 메소드인 `addSocketClient(Session session, String uuid, Object... args)`를 구현한다.
   * `ChatSocketClient`를 생성하여 `addSocketClient(SocketClient socketClient)`를 호출하도록 구현한다.
   * `args`는 `ChatSocketClient`에서 서비스용으로 추가된 Porperties를 받도록 구성한다.
2. 서비스에 툭화된 Properties를 관리하는 용도의 공용 메소드를 추가로 정의 할 수 있다.
   * `isExistUser` : 입력 받은 `userId`를 갖는 소켓 클라이언트가 존재하는지 여부를 확인하는 메소드
   * `setJoinRoom` : 입력 받은 `userId`를 갖는 소켓 클라이언트의 `roomId`를 입력 받은 `roomId`로 변경하는 메소드
   * `getRoomUserClientIdList` : 입력 받은 `roomId`를 갖는 소켓 클라이언트의 `uuid`를 리스트로 반환하는 메소드

##### 3.2.5. 소켓 프로토콜 정의서 확인 및 구현
> 프로토콜 정의서는 아래 이미지와 같이 작성 된 것으로 가정 하며, 이후 절차는 `사용자 관리`의 `친구 목록 조회`를 예시로 설명한다.
> ![img.png](/assets/img/post/websocket/bud-it-websocket-dev-guide/protocol-list-example.png)

1. 대분류에 해당하는 하위 패키지를 추가한다.
   * 이전 추가된 `....socket.chat` 패키지 하위에 `user` 패키지를 추가한다.
2. `dto` 패키지를 추가한다.
3. 서비스 클래스(`ChatUserSocketService`)를 추가한다.
   > 여기까지 처리하면 아래와 같은 구조가 된다. 소켓 서비스의 클래스명은 여러 소켓 서비스를 사용하는 경우 중복 되지 않도록 `UserSocketService` 보다는 서비스 명을 포함하도록 구성한다.
 
   ```shell
   ❯ tree ./user
   ./user
   ├── ChatUserSocketService.java
   └── dto
   ```

   1. `SocketService`를 상속받고, `SocketListener` 인터페이스를 구현하도록 구성한다.
      ```java
      @Slf4j
      @Service
      public class ChatUserSocketService extends SocketService implements SocketListener {
          public ChatUserSocketService(ObjectMapper objectMapper, ChatSocketClientPool socketClientPool) {
              super(objectMapper, socketClientPool);
          }
      
          @Override
          public void onOpen(Session session) {
          }
      
          @Override
          public void onMessage(String message, Session session) {
          }
      
          @Override
          public void onClose(Session session) {
          }
      }
      ```
      
   2. `onOpen`과 `onClose`는 클라이언트 관리용 서비스에서만 사용하므로 `/* IGNORE */`를 추가하여 빈 메소드임을 명시한다.
      ```java
          @Override
          public void onOpen(Session session) {
              /* IGNORE */
          }
      
      // ...
      
          @Override
          public void onClose(Session session) {
              /* IGNORE */
          }
      ```

   3. 사용자 DB처리등 비즈니스 로직 처리를 위한 `UserService`를 주입받도록 구성한다.
      ```java
      @Slf4j
      @Service
      public class ChatUserSocketService extends SocketService implements SocketListener {
          private final UserService userService;
      
          public ChatUserSocketService(ObjectMapper objectMapper, ChatSocketClientPool socketClientPool,
                                       UserService userService) {
              super(objectMapper, socketClientPool);
              this.userService = userService;
          }
      
          // ...
      }
      ```
   
   4. `ChatSocketController`에서 이벤트 발생시 호출 할 수 있도록 생성자에서 리스너로 자신을 등록 처리 한다.
      ```java
      // ...
          public ChatUserSocketService(ObjectMapper objectMapper, ChatSocketClientPool socketClientPool,
                                       UserService userService) {
              super(objectMapper, socketClientPool);
              this.userService = userService;
      
              ChatSocketController.addSocketListener(this);
          }
      // ...
      ```
      
   5. `onMessage` 메소드에서 커맨드를 수신하여 분기 할 수 있도록 기본형태(`switch`구문)를 구성한다.
      ```java
      // ...
          @Override
          public void onMessage(String message, Session session) {
              String command = getCommand(message);
              switch (command) {
      
              }
          }
      // ...
      ```
      > 이후 커맨드를 추가 할 때마다 `case`를 추가하여 분기 처리한다. 아래에 이어서 커맨드 추가 절차에 대해 알아 보겠다.

4. 커맨드 추가 절차
   1. 이전에 만들어 둔 `dto` 패키지에 `CS_GET_FRIEND` 커맨드의 파라미터를 수신 할 클래스를 추가한다. 클래스명은 커맨드명을 Camel Case로 변경 후 `Dto` suffix를 붙이는 형태로 한다.
   
      *CsGetFriendDto.java*
      ```java
      @AllArgsConstructor
      @NoArgsConstructor
      @Builder
      @Data
      public class CsGetFriendDto {
          private String clientId;
          private Long userId;
      }
      ```
      
   2. 마찬 가지로 Client에 응답 할 `SC_RES_FRIEND` 커맨드의 응답 데이터를 담을 클래스를 추가한다.
   
      *ScResFriendDto.java*
      ```java
      @AllArgsConstructor
      @NoArgsConstructor
      @Builder
      @Data
      public class ScResFriendDto {
          private Long userId;
          private String userName;
          private String onlineYn;
      }
      ```

   3. `ChatUserSocketService` 클래스에 `CS_GET_FRIEND` 커맨드를 처리 할 메소드를 추가한다.
      ```java
      // ...
          @Override
          public void onMessage(String message, Session session) {
              String command = getCommand(message);
              switch (command) {
                  case "CS_GET_FRIEND" -> handleCsGetFriend(getData(message, CsGetFriendDto.class), session);
              }
          }
      // ...
      ```
      * 커맨드를 처리하는 메소드는 `handle` prefix에 커맨드명을 Camel Case로 변경하여 사용한다.
      * `getData` 메소드는 `SocketService`에 구현되어 있으며, `message`에서 데이터를 추출하여 `clazz` 타입으로 반환한다.

   4. `handleCsGetFriend` 메소드를 추가한다.
      ```java
      private void handleCsGetFriend(CsGetFriendDto csGetFriendDto, Session session) {
          List<UserDto> userList = userService.getFriends(csGetFriendDto.getUserId());
          List<ScResFriendDto> scResFriendList = userList.stream()
                  .map(userDto -> objectMapper.convertValue(userDto, ScResFriendDto.class))
                  .toList();
          responseScResFriend(scResFriendList, session);
      }
      ```
      * 비즈니스 로직은 불가피한 경우를 제외하고, 각 서비스 클래스(예시의 경우 `UserService`)에서 처리하도록 구성한다.
      * 응답에 사용 할 데이터(`ScResFriendDto`)를 구성한다.
      * 클라이언트에 응답처리 하는 메소드는 `response` prefix에 커맨드명을 Camel Case로 변경하여 사용한다.
   
   5. `responseScResFriend` 메소드를 추가한다.
      ```java
      private void responseScResFriend(List<ScResFriendDto> scResFriendList, Session session) {
          send(SocketCommand.<List<ScResFriendDto>>builder()
                  .command("SC_RES_FRIEND")
                  .code(200)
                  .message("OK")
                  .data(scResFriendList)
                  .build(), session);
      }
      ```
      * `SocketService`에 구현되어 있는 `send` 메소드를 사용하여 응답을 전송한다.
   
   6. 필요한 경우 `broadcast` 메소드를 추가한다.
      * `broadcase` prefix에 `BC_XXXX` 커맨드의 `BC_`부분을 제외한 명령어 부분을 Camel Case로 변경하여 사용한다.
      * `SocketService`에 구현되어 있는 `broadcastAll` 또는 `broadcast` 메소드를 호출 하도록 구현 한다.
      *  추가한 `broadcastXxxx` 메소드는 `handleXxxx` 메소드에서 호출하도록 구성한다.

#### 3.3. 클라이언트
> 클라이언트 구현은 `NextJS`에서 구현하는 것을 예시로 설명한다.
> `NextJS` 프로젝트 생성은 완료 한 것으로 간주 한다.

##### 3.3.1. 필요 라이브러리 설치
> `recoil`을 사용하도록 구성 하였다. `recoil` 라이브러리를 설치한다.
```shell
$ npm install recoil
```
* `src/pages/` 경로에 `_app.tsx`를 추가하고, `recoil`을 사용하도록 구성한다.

   *src/pages/_app.tsx*
   ```typescript
   import {AppProps} from "next/app";
   import {RecoilRoot} from "recoil";
   
   function App({ Component, pageProps }: AppProps) {
     return (
       <RecoilRoot>
         <Component {...pageProps} />
       </RecoilRoot>
     );
   }
   
   export default App;
   ```
   * 참고: `tsx` 확장자는 `typescript xml`의 약자로, `React`에서 `XML`(`HTML`) 구문이 포함되는 파일에 사용한다. 위 `_app.tsx` 처럼
   `return` 구문에서 `html` 형태의 컴포넌트를 반환하도록 구현되는 경우 `tsx` 확장자를 사용하고, 로직으로 구성된 모듈의 경우 `ts` 확장자를 사용한다.
  
##### 3.3.2. `WebSocket` 관리를 위한 `recoil` 상태 추가
*src/atoms/web-socket.ts*
```typescript
import {atom} from "recoil";

/* 서버로 부터 수신 한 메시지 이력을 저장하기 위한 타입 */
export interface WebSocketMsgHistoryType {
  lastMessage: string|null;
  messageHistory: string[];
}

/* @deprecated 클라이언트 정보를 저장하기 위한 타입 */
export interface WebSocketClientInfoType {
  clientId: string|null;
}

/* WebSocket 객체를 저장하기 위한 recoil state */
const WebSocketState = atom<WebSocket|null>({
  key: 'webSocket',
  default: null,
});

/* 서버로 부터 수신 한 메시지 이력을 저장하기 위한 recoil state */
const WebSocketMsgHistoryState = atom<WebSocketMsgHistoryType>({
  key: 'webSocketMsgHistory',
  default: {
    lastMessage: null,
    messageHistory: [],
  }
});

/* @deprecated 클라이언트 정보를 저장하기 위한 recoil state */
const WebSocketClientInfoState = atom<WebSocketClientInfoType>({
  key: 'webSocketClientInfo',
  default: {
    clientId: null,
  }
});

export {WebSocketState, WebSocketMsgHistoryState, WebSocketClientInfoState};
```

##### 3.3.3. 서비스 진입점 작성 및 `WebSocket` 연결 처리
*src/pages/chat/index.tsx*
```typescript
import {useRecoilState} from "recoil";
import {useEffect} from "react";
import Router from "next/router";
import {WebSocketClientInfoState, WebSocketMsgHistoryState, WebSocketState} from "@/atoms/web-socket";

const ChatHome = () => {
  const [webSocket, setWebSocket] = useRecoilState(WebSocketState);
  const [webSocketMsgHistory, setWebSocketMsgHistory] = useRecoilState(WebSocketMsgHistoryState);
  const [, setWebSocketClientInfo] = useRecoilState(WebSocketClientInfoState);

  useEffect(() => {
    setWebSocket(new WebSocket("ws://localhost:8080/ws/chat"));
  }, []);

  useEffect(() => {
    if (webSocket !== null) {
      webSocket.onmessage = onReceiveSocketMessage;
    }
  }, [webSocket]);

  const onReceiveSocketMessage = (evt: MessageEvent) => {
    const resp = JSON.parse(evt.data);

    switch (resp.command) {
      case 'SC_HELO':
        webSocket?.send("CS_GET_CLIENT::" + JSON.stringify({
          clientId: sessionStorage.getItem("clientId"),
          userId: user.userId,
        }));
        break;

      case 'SC_RES_CLIENT':
        setWebSocketClientInfo({
          clientId: resp.data.clientId,
        });

        sessionStorage.setItem("clientId", resp.data.clientId);

        Router.push('/chat/friends');
        break;
    }

    setWebSocketMsgHistory({
      lastMessage: evt.data,
      messageHistory: [...webSocketMsgHistory.messageHistory, evt.data],
    });
  };

  return (
    <div>
      채팅 홈
    </div>
  );
}

export default ChatHome;
```
   1. 페이지 진입시 `WebSocket` 연결을 위한 `WebSocket` 객체를 생성하고, `WebSocketState`에 저장한다.
      ```typescript
      useEffect(() => {
        setWebSocket(new WebSocket("ws://localhost:8080/ws/chat"));
      }, []);
      ```
      * 서버단 구현시 `@ServerEndpoint(value = "/ws/chat")`에서 지정한 URL을 사용한다.
      * TODO: host(`ws://localhost`)와 port(`8080`)를 환경변수로 관리하도록 수정한다.
      
   2. `webSocket`에 값이 할당 된 후 `onmessage` 이벤트 핸들러를 할당하도록 구현한다.
      ```typescript
      useEffect(() => {
        if (webSocket !== null) {
          webSocket.onmessage = onReceiveSocketMessage;
        }
      }, [webSocket]);
      ```
      
   3. `onmessage`(`onReceiveSocketMessage`)에는 초기 클라이언트 식별 로직 및 이후 소켓을 이용하는 화면 구현시 사용 할 `WebSocketMsgHistoryState`에 메시지를 추가하는 로직으로 구성된다.
      ```typescript
      const onReceiveSocketMessage = (evt: MessageEvent) => {
        const resp = JSON.parse(evt.data);
      
        switch (resp.command) {
          case 'SC_HELO':
            webSocket?.send("CS_GET_CLIENT::" + JSON.stringify({
              clientId: sessionStorage.getItem("clientId"),
              userId: user.userId,
            }));
            break;
      
          case 'SC_RES_CLIENT':
            setWebSocketClientInfo({
              clientId: resp.data.clientId,
            });
      
            sessionStorage.setItem("clientId", resp.data.clientId);
      
            Router.push('/chat/friends');
            break;
        }
      
        setWebSocketMsgHistory({
          lastMessage: evt.data,
          messageHistory: [...webSocketMsgHistory.messageHistory, evt.data],
        });
      };
      ```
      * 초기 소켓 커맨드는 다음 순서로 진행된다.
         1. 서버에 연결되면(`@OnOpen`) 서버에서 클라이언트로 `SC_HELO` 커맨드를 전송한다.
         2. 클라이언트는 `SC_HELO` 커맨드를 수신하면 `CS_GET_CLIENT` 커맨드를 전송한다.
            * 기존에 연결된 적이 있는 클라이언트일 경우 기존에 연결했던 정보를 조회하여 클라이언트에 안내한다.
         3. 서버는 `CS_GET_CLIENT` 커맨드를 수신하면 `SC_RES_CLIENT` 커맨드를 전송한다.
            * 클라이언트에게 `clientId`를 전송한다.
            * 클라이언트는 `clientId`를 `sessionStorage`에 저장한다.
         4. 클라이언트는 `Router.push('/chat/friends')`를 호출하여 친구 목록 화면으로 이동한다.
            * 예시에서 실제 채팅 서비스의 초기 화면은 친구 목록 화면(`/chat/friends')이 된다.
      * 현재 수신한 메시지를 `recoil`의 `WebSocketMsgHistoryState`에 추가하여, 다른 화면에서도 사용 할 수 있도록 조치 한다.

##### 3.3.4. 서비스 화면 개발 예시
> `ChatHome`에서 `Router.push('/chat/friends')`를 호출하여 이동한 친구 목록 화면을 예시로 하여, 각 화면단 개발 방법에 대해 알아본다.

*src/pages/chat/friends.tsx*
```typescript
import {UserState} from "@/atoms/user";
import {useRecoilState} from "recoil";
import {WebSocketClientInfoState, WebSocketMsgHistoryState, WebSocketState} from "@/atoms/web-socket";
import {useEffect, useState} from "react";
import Router from "next/router";
import Friend from "@/components/Friend";
import {Button} from "@mui/material";

interface ScResFriendProps {
  userId: number;
  userName: string;
  onlineYn: string;
}
const Friends = () => {
  const [user] = useRecoilState(UserState);
  const [webSocket] = useRecoilState(WebSocketState);
  const [webSocketMsgHistory] = useRecoilState(WebSocketMsgHistoryState);

  const [friendList, setFriendList] = useState([] as ScResFriendProps[]);
  const [checkedFriendIds, setCheckedFriendIds] = useState([] as number[]);

  useEffect(() => {
    if (user.userId === -1) {
      alert("로그인이 필요합니다.");
      Router.push('/login');
    }

    // 친구 목록 조회
    webSocket?.send("CS_GET_FRIEND::" + JSON.stringify({
      clientId: sessionStorage.getItem("clientId"),
      userId: user.userId,
    }));
  }, []);

  useEffect(() => {
    if (webSocketMsgHistory.lastMessage === null) {
      return;
    }

    const resp = JSON.parse(webSocketMsgHistory.lastMessage);
    switch (resp.command) {
      case 'SC_RES_FRIEND':
        setFriendList(resp.data);
        break;

      case 'SC_RES_REG_ROOM':
        Router.push('/chat/room/' + resp.data.roomId);
        break;

      case 'BC_ONLINE':
        for (const element of friendList) {
          if (element.userId === resp.data.userId) {
            element.onlineYn = resp.data.onlineYn;
            break;
          }
        }
        setFriendList([...friendList]);
        break;
    }

  }, [webSocketMsgHistory]);

  const onFriendChecked = (id: number, checked: boolean) => {
    if (checked) {
      setCheckedFriendIds([...checkedFriendIds, id]);
    } else {
      setCheckedFriendIds(checkedFriendIds.filter((friendId) => friendId !== id));
    }
  };

  const onChatClick = () => {
    if (checkedFriendIds.length === 0) {
      alert("친구를 선택해주세요.");
      return;
    }

    webSocket?.send("CS_REG_ROOM::" + JSON.stringify({
      clientId: sessionStorage.getItem("clientId"),
      userId: user.userId,
      friendIdList: checkedFriendIds,
    }));
  };

  return (
    <div>
      <h1>친구목록</h1>
      {friendList.length === 0 && <div>친구가 없습니다.</div>}
      <div>
        {friendList.map((friend) => {
          return (
            <Friend key={friend.userId}
                    id={friend.userId}
                    name={friend.userName}
                    onlineYn={friend.onlineYn}
                    onChecked={onFriendChecked}
            />
          );
        })}
      </div>
      <div>
        <Button variant="contained" onClick={onChatClick}>대화하기</Button>
      </div>
    </div>
  );
};

export default Friends;
```

1. `WebSocket` 사용을 위해 관련 `recoil` 상태를 추가한다.
   ```typescript
   const [webSocket] = useRecoilState(WebSocketState);
   const [webSocketMsgHistory] = useRecoilState(WebSocketMsgHistoryState);
   ```
   * 웹 소켓 관련 상태는 진입점에서 세팅한 값을 가져와 사용만(Read Only)하므로 `setter`는 사용하지 않는다.

2. 페이지 진입시 초기값이 필요한 경우 `useEffect`에서 소켓 명령을 전송한다.(REST API 사용시와 동일하다.)
   ```typescript
   useEffect(() => {
     // 친구 목록 조회
     webSocket?.send("CS_GET_FRIEND::" + JSON.stringify({
       clientId: sessionStorage.getItem("clientId"),
       userId: user.userId,
     }));
   }, []);
   ```
   * webSocket은 `null`일 수 있으므로, `webSocket?.send` 형태로 호출한다.
   
3. 서버로부터 메시지를 수신하면, `WebSocketMsgHistoryState`에 저장되므로, 해당 변수인 `webSocketMsgHistory` 값이 바뀌는 것을 감지하도록 `useEffect`를 추가한다.
   ```typescript
   useEffect(() => {
     if (webSocketMsgHistory.lastMessage === null) {
       return;
     }
   
     const resp = JSON.parse(webSocketMsgHistory.lastMessage);
     switch (resp.command) {
   
     }
   }, [webSocketMsgHistory]);
   ```
   * `switch` 구문 내부에 현재 화면에서 사용하는 커맨드에 대해 수신 로직을 구현한다.
      * `SC_RES_FRIEND` : 친구 목록 조회 요청에 대한 응답
      * `SC_RES_REG_ROOM` : 채팅방 생성 요청에 대한 응답
      * `BC_ONLINE` : 친구 온라인 상태 변경 알림


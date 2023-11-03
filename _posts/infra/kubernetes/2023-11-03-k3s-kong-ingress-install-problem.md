---
layout: post
title: Kong Ingress 설치 및 문제 해결
date: 2023-11-03 11:51
description: K3S에 Kong Ingress 설치 방법 및 설치중 발생한 문제에 대한 해결 방법을 소개한다.
comments: true
categories: [ Infra, Kubernetes ]
tags: [ Kubernetes, K8s, K3s, Kong Ingress, Trouble Shooting, Setting ]
---

## 시작하며...
k3s 세팅 중 서비스 배포를 위해서 Ingress Controller를 설치해야 한다는 것을 알게 되었다.
아직도 `Ingress`의 역할을 명확하게 설명은 못하겠다. 대략적으로, 서비스 컨텍스트에 진입하기 윈한 진입점 역할을 수행하고, 
LoadBalancer, Proxy 역할을 수행한다는 정도인 듯 하다.
어떻든 MSA로 구성된 자체 서비스의 Gateway 역할이 필요하고, 이를 수행 할 수 있는 방법을 검토 하던 중 알게 되어 일단 설정 중인 상황이다.

## 이번 포스팅에서는...
Kong Ingress를 설치하는 방법은 간단했다. 이후 각 서비스와 연게하도록 설정하는 것이 일이 될 듯 하다.
Gateway 역할에 대한 설정은 다른 포스팅에서 다르도록 하고, 이번 포스팅에서는 설치 방법을  설명하고, 이때 나의 환경에서 발생했던 문제와
이를 해결하는 방법까지 이 포스팅에서 다룰 예정이다.

## Kong Ingress란?
위에서도 언급했듯이, 아직은 이녀석을 알아가는 중이다. 현재는 MSA 개념도상의 `API Gateway` 역할을 수행해 주는 것으로 이해하고 있다.

## 설치
> [MacOS에서 k3s 테스트 환경 구성](/posts/k3s-macos-init/) 에서는 VM으로 구성한 테스트 환경의 k3s 관리용 명령어로 `k3sctl`을 사용하였다.
> 이와 비슷하게 개발서버들을 관리하는 환경을 구축하였고, 이를 관리하는 명령어로 `devctl` alias를 생성하여 사용 하고 있다.
> 이후 사용하는 `devctl` 명령어는 각자 자신의 환경에 맞는 `kubectl` 명령어로 전환하여 사용해야 한다.

설치는 간단했다. 아래 명령으로 설치가 가능하다.
```shell
$ devctl apply -f https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v2.12.0/deploy/single/all-in-one-dbless.yaml
```

위 한줄 명령으로 설치가 완료된다.
하지만, 내가 관리하는 환경에서는 설치 가이드의 아래 설명부분이 제대로 작동하지 않았다.

## 문제 발생 및 해결 과정 
### 문제점 확인
설치 후 확인하는 단계에서 설치 가이드의 내용은 아래와 같다.

_출처 URL : https://konghq.com/blog/engineering/how-to-use-kong-gateway-with-k3s-for-iot-and-edge-computing-on-kubernetes_
```shell
$ curl -i $PROXY_IP
HTTP/1.1 404 Not Found
Date: Mon, 29 Jun 2020 20:31:16 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 48
X-Kong-Response-Latency: 0
Server: kong/2.0.4

{"message":"no Route matched with those values"}
```
위와 같이 응답이 오고, 아직 Gateway 설정이 없는 상태이므로 `no Route matched with those values` 메시지를 확인 할 수 있다는 것이 
설치가이드의 설명이었다.

하지만 나의 경우 아래와 같이 아예 커넥션이 발생되지 않았다.
```shell
$ curl -i http://192.168.61.41
curl: (28) Failed to connect to 192.168.61.41 port 80 after 25975 ms: Couldn't connect to server
```

`kong` 네임스페이스의 내용 검토 중 파드의 상태가 이상한것을 확인 할 수 있었다.
```shell
$ devctl get pods -n kong
NAME                          READY   STATUS    RESTARTS   AGE
proxy-kong-75579fffdb-spr7k   0/1     Running   0          41m
proxy-kong-75579fffdb-sk5tv   1/1     Running   0          41m
ingress-kong-94998c96-4bnr8   1/1     Running   0          41m
```
`proxy-kong` 파드중 1개가 READY 상태가 되지 못하고 있는 것을 확인했고, 
약 2일 가량 꽤 다양한 삽질(정확한 개념이 없는 상태에서의 검색 및 테스트 과정은 말 그대로 삽질이었다.)을 했고, 
우연히 정상 작동하게 된 케이스가 발생하여 해결 할 수 있었다.

### 문제점 해결
> 참조 URL : https://stackoverflow.com/questions/70663028/connection-refused-trying-to-connect-via-ingress-interface
> 구글 검색 키워드 : k3s kong ingress port 80 connection time out
> 앞에서도 이야기 했지만, 위 링크의 내용을 살펴보면 내가 겪고 있는 문제와 무관하다. 단지 이런 설정도 있네 하면서, 적용해 보았고, 정상 작동이 되는
> 상태이다. 핵심적인 문제가 뭐였는지, 그래서 어떤점이 해소되어 해결된건지에 대한 설명은 현재로선 불가능 하다.

옵션을 적용하기 위해서 yaml을 로컬에 다운로드하였다.
```shell
$ curl https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v2.12.0/deploy/single/all-in-one-dbless.yaml > kong-ingress.yaml
```

다운로드한 yaml의 `proxy-kong` `Deployment` 설정 부분을 찾아서 `hostNetwork: true` 설정을 추가하였다.
```yaml
# ...
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: proxy-kong
  name: proxy-kong
  namespace: kong
spec:
  replicas: 2
  selector:
    matchLabels:
      app: proxy-kong
  template:
    metadata:
      annotations:
        kuma.io/gateway: enabled
        kuma.io/service-account-token-volume: kong-serviceaccount-token
        traffic.sidecar.istio.io/includeInboundPorts: ""
      labels:
        app: proxy-kong
    spec:
      hostNetwork: true   # <========== 이부분을 추가 함.
      automountServiceAccountToken: false
      containers:
# ...
```

변경된 yaml을 이용하여 설치 
```shell
$ devctl apply -f kong-ingress.yaml
# ...

$ devctl get pod -n kong -o wide
NAME                          READY   STATUS    RESTARTS   AGE    IP              NODE             NOMINATED NODE   READINESS GATES
proxy-kong-54688b5f65-hv624   1/1     Running   0          3m3s   192.168.61.41   bud-itserver     <none>           <none>
proxy-kong-54688b5f65-9q7h4   1/1     Running   0          3m3s   10.112.117.7    k3s-dev-worker   <none>           <none>
ingress-kong-94998c96-zcp79   1/1     Running   0          3m3s   10.42.1.41      k3s-dev-worker   <none>           <none>

$ devctl get svc -n kong -o wide
NAME                      TYPE           CLUSTER-IP     EXTERNAL-IP                  PORT(S)                      AGE     SELECTOR
kong-admin                ClusterIP      None           <none>                       8444/TCP                     3m44s   app=proxy-kong
kong-validation-webhook   ClusterIP      10.43.47.222   <none>                       443/TCP                      3m44s   app=ingress-kong
kong-proxy                LoadBalancer   10.43.96.201   10.112.117.7,192.168.61.41   80:30062/TCP,443:30953/TCP   3m44s   app=proxy-kong

$ curl -i http://192.168.61.41
HTTP/1.1 404 Not Found
Date: Fri, 03 Nov 2023 06:00:03 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 52
X-Kong-Response-Latency: 1
Server: kong/3.4.2

{
  "message":"no Route matched with those values"
}%
```
좀 허망하다 싶을 정도로 잘 작동한다.

이제 각 마이크로 서비스별 ingress 설정을 추가하여 이 kong ingress controller 라는 녀석을 통해서 외부에 서비스 하도록 설정하는 방법을 추가로 스터디 할 예정이다.

## 새롭게 알게 된 내용
2일 가량 두서없이 자료조사를 하고 실패를 반복한 상태라, 크게 남아 있는건 없지만, 기억나는 몇가지를 정리 해보고자 한다.

### Readiness probe failed
정확히 어떤 내용을 확인하다 보게 된 오류인지 기억은 안나지만, `Readiness probe failed`라는 내용을 확인 할 수 있었다.
`readiness`는 pod가 뜬 후에 정상적으로 떳는지 확인하기 위한 URI를 의미한다는 것을 알게 되었다. 
관련 정보를 아래와 같이 확인 할 수 있다.
```shell
$ devctl describe pod proxy-kong-54688b5f65-hv624 -n kong
Name:             proxy-kong-54688b5f65-hv624
Namespace:        kong
Priority:         0
Service Account:  kong-serviceaccount
Node:             bud-itserver/192.168.61.41
Start Time:       Fri, 03 Nov 2023 14:57:52 +0900
Labels:           app=proxy-kong
                  pod-template-hash=54688b5f65
Annotations:      kuma.io/gateway: enabled
                  kuma.io/service-account-token-volume: kong-serviceaccount-token
                  traffic.sidecar.istio.io/includeInboundPorts:
Status:           Running
IP:               192.168.61.41
IPs:
  IP:           192.168.61.41
Controlled By:  ReplicaSet/proxy-kong-54688b5f65
Containers:
  proxy:
    Container ID:   containerd://9e146e2c17e5a26339904ec9b9369627bd5167ca0bc282d643727fb7fb1b3b6a
    Image:          kong:3.4
    Image ID:       docker.io/library/kong@sha256:6b5506ae271bc252fe9594a808db7146b488e0a88966c640d320abd6dedc1ef2
    Ports:          8000/TCP, 8443/TCP, 8100/TCP
    Host Ports:     8000/TCP, 8443/TCP, 8100/TCP
    State:          Running
      Started:      Fri, 03 Nov 2023 14:57:54 +0900
    Ready:          True
    Restart Count:  0
    Liveness:       http-get http://:8100/status delay=5s timeout=1s period=10s #success=1 #failure=3
    Readiness:      http-get http://:8100/status/ready delay=5s timeout=1s period=10s #success=1 #failure=3
    Environment:
      KONG_PROXY_LISTEN:            0.0.0.0:8000 reuseport backlog=16384, 0.0.0.0:8443 http2 ssl reuseport backlog=16384
      KONG_PORT_MAPS:               80:8000, 443:8443
      KONG_ADMIN_LISTEN:            0.0.0.0:8444 http2 ssl reuseport backlog=16384
      KONG_STATUS_LISTEN:           0.0.0.0:8100
      KONG_DATABASE:                off
      KONG_NGINX_WORKER_PROCESSES:  2
      KONG_KIC:                     on
      KONG_ADMIN_ACCESS_LOG:        /dev/stdout
      KONG_ADMIN_ERROR_LOG:         /dev/stderr
      KONG_PROXY_ERROR_LOG:         /dev/stderr
      KONG_ROUTER_FLAVOR:           traditional
    Mounts:                         <none>
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  kong-serviceaccount-token:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>
```
중간 쯤에 보면 `Readiness:      http-get http://:8100/status/ready delay=5s timeout=1s period=10s #success=1 #failure=3`
부분이 해당 설정 내용으로, 해당 파드가 뜬 후 5초 후에 10초 간격으로 에 `8100`포트로 붙어서 `/status/ready`를 호출 하고, 3회 실패하면 체크를 
중지 한다는 설정인 듯 하다. 이 호출이 성공을 해야 파드의 상태가 Ready가 된다는 것 같다.

다음과 같은 방법으로 관리용 PC에서 포트 포워딩 설정하여 접속해서 오류가 발생하고 있는 것을 확인해 볼 수 있었다.
```shell
$ devctl port-forward proxy-kong-75579fffdb-72xdj -n kong 8100:8100
Forwarding from 127.0.0.1:8100 -> 8100
Forwarding from [::1]:8100 -> 8100

$ curl -i http://localhost:8100/status/ready
HTTP/1.1 503 Service Temporarily Unavailable
Date: Thu, 02 Nov 2023 10:23:02 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Access-Control-Allow-Origin: *
Content-Length: 70
X-Kong-Admin-Latency: 2
Server: kong/3.4.2

{"message":"no configuration available (empty configuration present)"}%
```
참고로 정상적으로 Ready 상태가 된 파드에 붙어보면 아래와 같이 표시되었다.
```shell
$ curl -i http://localhost:8100/status/ready
HTTP/1.1 200 OK
Date: Fri, 03 Nov 2023 07:21:01 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Access-Control-Allow-Origin: *
Content-Length: 19
X-Kong-Admin-Latency: 2
Server: kong/3.4.2

{"message":"ready"}%
```

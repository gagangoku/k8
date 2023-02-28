# Kafka setup
https://kafka.apache.org/quickstart
- first run single node kafka with KRaft locally ✅
- then on docker ✅
- then on minikube (skipped)
- then on Kubernetes ✅

Use https://github.com/provectus/kafka-ui for UI


## Local setup (baremetal)
Follow the quickstart guide here - https://kafka.apache.org/quickstart
Simple, easy, works !

## Local docker setup
Am forgetting the tutorial i followed, but was able to run kafka locally using docker compose, and the Provectus UI for Kafka as well:
```bash
docker-compose up -d
```

## Minikube
Skipped this and directly went to Kubernetes

## Kubernetes setup
#### Failure
From https://github.com/IBM/kraft-mode-kafka-on-kubernetes/blob/main/kubernetes/kafka.yml 

```bash
$ docker build -t gagangoku1/kafka:1.0.2
$ docker run -v /opt/kafka:/opt/kafka-share -p 9092:9092 -p 9093:9093 -e HOSTNAME=kafka-0 -e SHARE_DIR=/opt/kafka-share -e REPLICAS=3 -e SERVICE=kafka-svc -e NAMESPACE=kafka-kraft -d gagangoku1/kafka:1.0.2
```

NOTE: ReadWriteMany fails with GCE PD because its not supported:
```bash
failed to provision volume with StorageClass "manual": rpc error: code = InvalidArgument desc = VolumeCapabilities is invalid: specified multi writer with mount access type
```
ReadWriteOnce will let kafka-0 statefulset come up, but then kafka-1 will fail because the persistent volume is already mounted.

Solution:
- this article suggests creating multiple pv (https://www.codegravity.com/blog/kafka-local-persistent-volume-with-kubernetes)
- this article suggests local persistent volume (https://banzaicloud.com/blog/kafka-on-kubernetes/)
- this article suggests volumeClaimTemplate (https://zhimin-wen.medium.com/persistent-volume-claim-for-statefulset-8050e396cc51)
- This also suggests volumeClaimTemplate (https://learnk8s.io/kafka-ha-kubernetes)

Trying volumeClaimTemplate now
Kafka is up. Some errors in the log like:
```bash
  [2023-02-28 01:48:54,705] ERROR [RaftManager nodeId=2] Unexpected error INCONSISTENT_CLUSTER_ID in BEGIN_QUORUM_EPOCH response: InboundResponse(correlationId=1349, data=BeginQuorumEpochResponseData(errorCode=104, topics=[]), sourceId=0) (org.apache.kafka.raft.KafkaRaftClient)
  [2023-02-28 01:50:23,633] ERROR [RaftManager nodeId=0] Unexpected error INCONSISTENT_CLUSTER_ID in VOTE response: InboundResponse(correlationId=4071, data=VoteResponseData(errorCode=104, topics=[]), sourceId=1) (org.apache.kafka.raft.KafkaRaftClient)
  [2023-02-28 01:50:23,637] WARN [RaftManager nodeId=0] Graceful shutdown timed out after 5000ms (org.apache.kafka.raft.KafkaRaftClient)
  [2023-02-28 01:50:23,638] ERROR [kafka-raft-io-thread]: Graceful shutdown of RaftClient failed (kafka.raft.KafkaRaftManager$RaftIoThread)
  java.util.concurrent.TimeoutException: Timeout expired before graceful shutdown completed
    at org.apache.kafka.raft.KafkaRaftClient$GracefulShutdown.failWithTimeout(KafkaRaftClient.java:2416)
    at org.apache.kafka.raft.KafkaRaftClient.maybeCompleteShutdown(KafkaRaftClient.java:2163)
    at org.apache.kafka.raft.KafkaRaftClient.poll(KafkaRaftClient.java:2230)
    at kafka.raft.KafkaRaftManager$RaftIoThread.doWork(RaftManager.scala:61)
    at kafka.utils.ShutdownableThread.run(ShutdownableThread.scala:96)
```
This was because of older persistent volume. I deleted them and recreated the statefulset and it worked.

Next error:
- kafka 1 and 2 are ready
- kafka 0 is not connecting to them because:
```bash
  [2023-02-28 01:57:45,467] INFO [RaftManager nodeId=0] Node 2 disconnected. (org.apache.kafka.clients.NetworkClient)
  [2023-02-28 01:57:45,467] WARN [RaftManager nodeId=0] Connection to node 2 (kafka-2.kafka-svc.kafka-kraft.svc.cluster.local/10.4.0.34:9093) could not be established. Broker may not be available. (org.apache.kafka.clients.NetworkClient)
```

Login into the container and lets figure this out:
```bash
  $ apt-get update -y
  $ apt-get install -y iputils-ping net-tools dnsutils netcat
```

I think its a kafka configuration problem.


#### Success (finally) !
Followed https://learnk8s.io/kafka-ha-kubernetes

This worked, and was able to bring up a decent kafka 3 broker cluster which is connecting with each other.

Verified kafka producer / consumer working properly using:
```bash
kubectl run kafka-client --rm -ti --image bitnami/kafka:3.1.0 -- bash

$ kafka-console-producer.sh --topic test --request-required-acks all --bootstrap-server kafka-0.kafka-svc.kafka-kraft-ns.svc.cluster.local:9092,kafka-1.kafka-svc.kafka-kraft-ns.svc.cluster.local:9092,kafka-2.kafka-svc.kafka-kraft-ns.svc.cluster.local:9092
$ kafka-console-consumer.sh --topic test --from-beginning --bootstrap-server kafka-0.kafka-svc.kafka-kraft-ns.svc.cluster.local:9092,kafka-1.kafka-svc.kafka-kraft-ns.svc.cluster.local:9092,kafka-2.kafka-svc.kafka-kraft-ns.svc.cluster.local:9092
```
Provectus UI also worked nicely with it.

NOTE: Currently provectus UI is running as username password authorization (which is basic).
I tried oauth2 from https://github.com/provectus/kafka-ui/blob/master/documentation/guides/SSO.md, but container failed:


```java
Caused by: org.springframework.beans.BeanInstantiationException: Failed to instantiate [org.springframework.security.oauth2.client.registration.InMemoryReactiveClientRegistrationRepository]: Factory method 'clientRegistrationRepository' threw exception; nested exception is java.lang.IllegalArgumentException: registrations cannot be null or empty
 at org.springframework.beans.factory.support.SimpleInstantiationStrategy.instantiate(SimpleInstantiationStrategy.java:185)
 at org.springframework.beans.factory.support.ConstructorResolver.instantiate(ConstructorResolver.java:653)
 ... 55 common frames omitted
Caused by: java.lang.IllegalArgumentException: registrations cannot be null or empty
 at org.springframework.util.Assert.notEmpty(Assert.java:470)
 at org.springframework.security.oauth2.client.registration.InMemoryReactiveClientRegistrationRepository.toUnmodifiableConcurrentMap(InMemoryReactiveClientRegistrationRepository.java:83)
 at org.springframework.security.oauth2.client.registration.InMemoryReactiveClientRegistrationRepository.<init>(InMemoryReactiveClientRegistrationRepository.java:65)
 at com.provectus.kafka.ui.config.auth.OAuthSecurityConfig.clientRegistrationRepository(OAuthSecurityConfig.java:107)
```

Config was:
```
   - name: AUTH_TYPE
     value: "OAUTH2"
   - name: SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_AUTH0_CLIENTID
     value: "rosZIWiUDVCtXiedz6voqIdSA19STdmU"
   - name: SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_AUTH0_CLIENTSECRET
     value: "mx3s5Ak2DyvjnsKOLHVZ9nNc5X_K9xkAc7LuMdVlHI6lhD6FtVOONAj9LE4gdNYN"
   - name: SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_AUTH0_ISSUER_URI
     value: "https://dev-h3yoouiotrd14lqt.us.auth0.com/"
   - name: SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_AUTH0_SCOPE
     value: "openid"
```

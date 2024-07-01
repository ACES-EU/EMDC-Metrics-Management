# Aces Metrics Hanlder
Will operate in the EMDC level to extract metrics and efficiently organize them.
Licensed under MIT license

### Key Components
+ `Storage Components`: Object Storage (MinIO), Timeseries DB (TimescaleDB), Graph Store (Neo4j)
+ `Metrics Catalogue`: REST API that exposes stored information and data in all storages
+ `Pull-Push Metrics Pipelines`: Confluent Kafka, Prometheus, Metrics Scrapper
+ `Metrics Consumer`: Kafka Consumer which receives extracted metrics

### Installation Steps & Prerequisites
Before starting the installation, please make sure that you have a storageclass and please change the 
hostPaths in Persistent Volume declarations. For instance you need to create a directory called pvs and for timescaledb
create a folder inside the parent dir called timescale. After that copy paste the absolute path to your PV declaration. Example

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: timescaledb-pv-volume
  labels:
    type: local
spec:
  storageClassName: hostpath
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/Users/panagiotiskapsalis/PycharmProjects/MARTEL-PROJECTS/ACES Deployment/pvs/timescaledb"
```
#### 2. Storage Components
```shell
cd config/k8s/external/storage-components
```
##### 2.1 Install Neo4j
```shell
cd neo4j/standalone
bash setup.sh
```
##### 2.2 Install TimescaleDB
```shell
cd timescaledb
kubectl apply -f .
```
##### 2.3 Port Forward Storage Components
###### 2.3.1 Neo4j
```shell
kubectl port-forward svc/neo4j 7474:7474
```
###### 2.3.2 Timescaledb
```shell
kubectl port-forward svc/timescaledb 5432:5432
```
#### 3. Metrics Catalogue
0. `How to build Metrics catalogue dockerfile` see documentation [here](metrics_catalogue/README.md)
2. `cd config/k8s/aces/metrics_catalogue`
3. `kubectl apply -f .`
4. `kubectl port-forward svc/metrics-catalogue 8000:8002`
5. Init the Metrics Management System using the following CURL API
```shell
curl -X 'GET' \
  'http://localhost:8000/init' \
  -H 'accept: application/json'
```

#### 4. Pull-push Metrics Pipeline
`cd config/k8s/external/pull-push-pipeline`
##### 4.1 Deploy Confluent Kafka
1. `cd kafka`
2. `kubectl apply -f .`
##### 4.2 Deploy Prometheus
1. `cd prometheus`
2. `bash setup.sh`
##### 4.3 Deploy Metrics Scraper
1. `cd prom-adapter`
2. `kubectl apply -f .`

In this step you need to wait for kafka being healthy and the same for prometheus
port forward the services with the following commands:

```shell
kubectl port-forward svc/control-center 9021:9021
```

```shell
kubectl port-forward svc/prometheus-server 9000:80
```

##### 4.4 Port Forward Control Center
```shell
kubectl port-forward svc/control-center 9021:9021
```

##### Increase the number of partitions in metrics topic
2. `Commands to execute for the Kafka Broker`
Firstly you need to connect to Kafka Broker pod for instance:
```shell
kubectl exec -it ${kafka_broker_pod_id} bash
```

Describe a consumer group
```shell
kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group aces_metrics_consumer
```
Describe a topic
```shell
kafka-topics --bootstrap-server localhost:9092 --describe --topic metrics
```

Alter a topic (change partitions)
```shell
kafka-topics --bootstrap-server localhost:9092 --alter --topic metrics --partitions 2
```

List all topics
```shell
 kafka-topics --list --bootstrap-server localhost:9092
```

#### 5. Metrics Consumer
1. `cd config/k8s/aces/metrics_consumer`
2. `kubectl apply -f .`
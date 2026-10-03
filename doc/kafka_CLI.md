<style>
body {
  font-family: "Spectral", "Gentium Basic", Cardo , "Linux Libertine o", "Palatino Linotype", Cambria, serif;
  font-size: 100% !important;
  padding-right: 2%;
}
code {
  padding: 0.25em;
	
  white-space: pre;
  font-family: "Tlwg mono", Consolas, "Liberation Mono", Menlo, Courier, monospace;
	
  background-color: #ECFFFA;
  //border: 1px solid #ccc;
  //border-radius: 3px;
}

kbd {
  display: inline-block;
  padding: 3px 5px;
  font-family: "Tlwg mono", Consolas, "Liberation Mono", Menlo, Courier, monospace;
  line-height: 10px;
  color: #555;
  vertical-align: middle;
  background-color: #ECFFFA;
  border: solid 1px #ccc;
  border-bottom-color: #bbb;
  border-radius: 3px;
  box-shadow: inset 0 -1px 0 #bbb;
}

h1,h2,h3,h4,h5 {
  color: #269B7D; 
  font-family: "fira sans", "Latin Modern Sans", Calibri, "Trebuchet MS", sans-serif;
}

</style>

# Kafka CLI
## `kafka-topic`
```bash
~/git/kafka-security-setup$ docker exec broker-1 kafka-topics \
  --bootstrap-server broker-1:29092 \
  --list

~/git/kafka-security-setup$ ./create-topic.sh payments
Trying to create the topic payments if not yet present.
List of all topics already present: 
The topic payments is still absent.
Created topic payments.
current list of topics:
payments
Description of the payments topic:
Topic: payments TopicId: YOeMDv0MQtCzrfUUjcogeA PartitionCount: 1       ReplicationFactor: 1 Configs: min.insync.replicas=1
        Topic: payments Partition: 0    Leader: 1       Replicas: 1     Isr: 1       Elr:    LastKnownElr: 
~/git/kafka-security-setup$ docker exec broker-1 kafka-topics --bootstrap-server broker-1:29092 --list
payments
~/git/kafka-security-setup$
```

## `kafka-console-consumer`
```bash
~/git/kafka-security-setup$ docker exec -it broker-1 kafka-console-consumer \
  --bootstrap-server broker-1:29092 \
  --topic payments \
  --from-beginning
{"user": "dirty harry", "amount": 5000, "card-nr": "SNARF-1234-XXXX-29092"}
{"user": "Severus van Buren", "amount": 3300, "card-nr": "SvBu-1313-XXXX-29092"}
{"user": "Guust Flater", "amount": 23.55, "card-nr": "GuFl-8912-XXXX-29092"}
^CProcessed a total of 3 messages
~/git/kafka-security-setup$   
```

## `kafka-console-producer`
```bash
~/git/kafka-security-setup$ docker exec -it broker-1 kafka-console-producer \
  --bootstrap-server broker-1:29092 \
  --topic payments
>{"user": "dirty harry", "amount": 5000, "card-nr": "SNARF-1234-XXXX-29092"}
>{"user": "Severus van Buren", "amount": 3300, "card-nr": "SvBu-1313-XXXX-29092"}
>{"user": "Guust Flater", "amount": 23.55, "card-nr": "GuFl-8912-XXXX-29092"}
>~/git/kafka-security-setup$ 
```

## `kafka-get-offsets`
before sending any event to the `payments` topic
```bash
~/git/kafka-security-setup$ docker exec broker-1 kafka-get-offsets \
  --bootstrap-server broker-1:29092 \
  --topic payments
payments:0:0
~/git/kafka-security-setup$ 
```
after sending any event to the `payments` topic
```bash
~/git/kafka-security-setup$ docker exec broker-1 kafka-get-offsets \
  --bootstrap-server broker-1:29092 \
  --topic payments
payments:0:3
~/git/kafka-security-setup$ 
```
- `payments:0:3` means
  - topic name: `payments`
  - partition index: `0`
  - current offset: `3`
- compare with the `__consumer_offsets` topic that is created as soon as `kafka-console-consumer` is started for the 
  first time:
```bash
~/git/kafka-security-setup$ docker exec broker-1 kafka-get-offsets \
  --bootstrap-server broker-1:29092 \
  --topic __consumer_offsets
__consumer_offsets:0:0
__consumer_offsets:1:0
__consumer_offsets:10:0
__consumer_offsets:11:0
__consumer_offsets:12:4
__consumer_offsets:13:0
__consumer_offsets:14:0
__consumer_offsets:15:0
__consumer_offsets:16:0
__consumer_offsets:17:0
__consumer_offsets:18:0
__consumer_offsets:19:0
__consumer_offsets:2:0
__consumer_offsets:20:0
__consumer_offsets:21:0
__consumer_offsets:22:0
__consumer_offsets:23:0
__consumer_offsets:24:0
__consumer_offsets:25:0
__consumer_offsets:26:0
__consumer_offsets:27:0
__consumer_offsets:28:0
__consumer_offsets:29:0
__consumer_offsets:3:0
__consumer_offsets:30:0
__consumer_offsets:31:0
__consumer_offsets:32:0
__consumer_offsets:33:0
__consumer_offsets:34:0
__consumer_offsets:35:0
__consumer_offsets:36:0
__consumer_offsets:37:0
__consumer_offsets:38:0
__consumer_offsets:39:0
__consumer_offsets:4:0
__consumer_offsets:40:0
__consumer_offsets:41:0
__consumer_offsets:42:0
__consumer_offsets:43:0
__consumer_offsets:44:0
__consumer_offsets:45:0
__consumer_offsets:46:0
__consumer_offsets:47:0
__consumer_offsets:48:0
__consumer_offsets:49:0
__consumer_offsets:5:0
__consumer_offsets:6:0
__consumer_offsets:7:0
__consumer_offsets:8:0
__consumer_offsets:9:0
~/git/kafka-security-setup$ 
```
- here the partition with index `12` holds the offset value `4`

## Resources
- [https://www.perplexity.ai/search/ea58049b-639e-4061-aa09-3b391299e39d](https://www.perplexity.ai/search/ea58049b-639e-4061-aa09-3b391299e39d)
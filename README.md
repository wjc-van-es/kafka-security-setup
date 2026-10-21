# kafka-security-setup

## Context
This project attempts to demonstrate how a Kafka cluster can be secured in subsequent steps, each building on the 
previous one and making the cluster and its resources more secure.

1. The first step is to _encrypt the data communication_ between the Kafka cluster and its clients, in particular
   _producers_, which write events to a specified topic, and
   _consumers_, which read those events from a specified topic.

   For this to work we need to use the _Public Key Infrastructure_ (PKI) and the _Transport Layer Security_ (TLS) 
   protocol. The principle is that the Kafka broker's each have their _private key / public certificate pair_ configured, 
   with which they can authenticate themselves with the clients and negotiate a secure connection. In such a secure 
   connection data can be encrypted by the sender and decrypted by the receiver. The client and the broker can both act 
   as sender and receiver.
 
2. The second step would be to enforce _client side authentication_. If we need to restrict the access to the resources
   of our Kafka cluster, the first step would be to be able to identify that client. There are a lot of ways to do this
   1. _mTLS_, where each client would also have a private key / public certificate pair configured.
   2. _Simple Authentication and Security Layer_ (SASL), which comes in several flavors.

3. The third step would be _authorization_ of the known (authenticated) clients. Usually not all clients ought to have
   access to all available resources. After establishing the identity of a client through the chosen authentication 
   protocol the cluster needs to establish rules on what resources it may access and what operations it may perform on 
   them.
   1. _Access Control Lists_ (ACLs) are a way to define such rules for all authenticated clients.

## Demos
We will use _Docker Compose_ yaml files to configure simple Kafka clusters, that demonstrate each subsequent step of 
securing a Kafka cluster. As the configuration of each of these steps is quite involved, I will explain them each in 
their own Markdown file.

1. For data transport encryption see [doc/01_encrypting_data_transfer.md](doc/01_encrypting_data_transfer.md#encrypting-data-transfer-between-kafka-brokers-and-clients)
2. For client authentication see ...
3. For client authorization see ...

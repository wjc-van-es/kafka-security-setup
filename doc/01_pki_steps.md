<style>
body {
  font-family: "Spectral", "Gentium Basic", Cardo , "Linux Libertine o", "Palatino Linotype", Cambria, serif;
  font-size: 100% !important;
  padding-right: 12%;
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

# PKI

## Context
- we want to set up a PKI configuration to establish 2 things:
  - encrypted communication between the Kafka broker cluster and its clients.
  - authentication of the Kafka broker cluster with its clients
- This is realized using the TLS (Transport Layer Security) protocol. This is the successor of the SSL 
  (Secure Socket Layer) protocol. In many places SSL is still used in names of encryption tools and libraries, but if 
  you use a contemporary version you can rest assured that it is actually a version of TLS you are using.

### For this we have to set up the following
- an asymmetric private key and public certificate pair
- a keystore to store them both on the server side (the kafka cluster side)
- a newly generated csr (certificate signing request) from the key and certificate pair to send to a CA 
  (Certificate Authority) 
- the csr signed by the CA with one of its own private keys
- signing the key/certificate pair inside the keystore with the signed csr
- a truststore for the client where the public certificate of the CA is imported belonging to the private key with 
  which the csr was signed

### TLS Handshake when client and broker establish a connection
1. Client Hello - containing info about
   1. encryption ciphers and algorithms supported / accepted by the client
   2. TLS version
2. Server Hello - containing 
   1. Certificate
   2. selected cipher
3. Client scrutinizes the brokers certificate. It should comply with the following demands:
   1. Is it signed by a CA, whose certificate is in my truststore? 
   2. Does the hostname matches the one on the certificate?
4. If both answers are a yes, it confirms the broker's identity. In other words these checks are necessary for a 
   positive **server-side authentication**. the connection only commences when the broker is thus authenticated 
   otherwise it will be refused by the client.
   1. In a Java Client this will lead to a ... Exception
   2. You can configure a connection in a Java Client in such a way that it will ignore a hostname match, or you can 
      import a self-signed certificate from a server into the client's truststore. This is sometimes done in a test 
      environment, and it still enables encrypted communication. However, it seriously undermines server-side 
      authentication and should never be done in production.

## Steps to get TLS encrypted connection between the Kafka broker cluster & its clients
1. Here we are going to create a private key / public certificate pair to mimic one of a genuine CA. So in reallife
   scenario's this is skipped. We create one using this script [`../tls`](../tls/generate-ca.sh), which
   uses the `openssl` CLI. To install
   1. On Debian based Ubuntu, Mint use:
      ```bash
      sudo apt update # checking updates
      sudo apt install openssl libssl-dev # the actual installation
      openssl version # verify the installation
      ```
   2. On Apple MacBooks use [Homebrew](https://brew.sh/)
2. Generate a truststore for the client with the `keytool` CLI that is a part of the JDK.
   1. When you have multiple JDK versions installed (e.g. with SDKMan!) check in your terminal, which one you are 
      running and match it with the one you want to use for your project:
      1. `java -XshowSettings:properties --version` or with SDKMan!
      2. `sdk current java` and change when needed, e.g.: `sdk use java 25.0.3-tem`
   2. now run the script [`../tls`](../tls/generate-truststore.sh)

## Docker compose yaml definition
- [`../docker-compose-tls.yml`](../docker-compose-tls.yml)

### resources

#### How to use secrets in a `docker-compose.yml` file to prevent hardcoded passwords to get into the git repo
- [https://www.perplexity.ai/search/2efa9ac2-1070-4fea-9a01-65631b799d7e](https://www.perplexity.ai/search/2efa9ac2-1070-4fea-9a01-65631b799d7e)

## Tests

1. start the docker cluster

   `~/git/kafka-security-setup$ docker compose -f docker-compose-tls.yml up -d`

2. we can test whether the password environment variables were successfully set with the configured secrets via the
   `entrypoint` definition in by checking:

   ```bash
   docker exec -it broker-1 bash -c \
     'tr "\0" "\n" < /proc/1/environ | grep "^KAFKA_SSL_"'
   ```
   
3. add `basic_topic` with idempotent script

   `~/git/kafka-security-setup$ ./create-topic.sh basic-topic`

4. start [`nl.vea.kafka.security.encryption.BasicSSLConsumer`](../src/main/java/nl/vea/kafka/security/encryption/BasicSSLConsumer.java)
   
   The execution of this Java application relies on the following environment variables being set, (we chose to use a
   `.env` file, but this is excluded from git and  added in [../.gitignore](../.gitignore) to keep local secrets private)
   1. `TRUSTSTORE_LOCATION` - the absolute path to the truststore we generated
   2. `CLIENT_SECRET` - the password we use for this truststore
   3. `DEBUG_SSL_HANDSHAKE` - should be parsable to a boolean - if present and true SSL handshake debug logging is performed

5. start [`nl.vea.kafka.security.encryption.BasicSSLProducer`](../src/main/java/nl/vea/kafka/security/encryption/BasicSSLProducer.java)

   The execution of this Java application relies on the same environment variables being set:
   1. `TRUSTSTORE_LOCATION` - the absolute path to the truststore we generated
   2. `CLIENT_SECRET` - the password we use for this truststore
   3. `DEBUG_SSL_HANDSHAKE` - should be parsable to a boolean - if present and true SSL handshake debug logging is performed

6. When all is well you will see in the logging of `BasicSSLProducer` 10 messages being produced and send to the 
   `basic-topic` and in the logging of `BasicSSLConsumer`, you see how these are consumed from that topic.

7. We could also use the Kafka CLI clients
   ```bash
    docker exec -it broker-1 kafka-console-consumer \
    --bootstrap-server broker-1:9094 \
    --topic basic-topic \
    --command-config /etc/kafka/secrets/client-ssl.properties \
    --from-beginning
    ```
   1. For this to work we had to configure a separate `CLI` listener in 
      [../docker-compose-tls.yml](../docker-compose-tls.yml), because the `kafka-console-consumer` starting inside
      the `broker-1` Docker container. If the `kafka-console-consumer` would use the `CLIENT` listener inside broker-1,
      localhost:9092 initially reaches the listener only if it is bound to loopback or all interfaces. 

      At least this was the case when [../docker-compose-tls.yml](../docker-compose-tls.yml) still configured the
      `CLIENT` listener in the `KAFKA_LISTENERS` list as `CLIENT://broker-1:9092`
      
      combined with the `CLIENT://localhost:9092` setting in the `KAFKA_ADVERTISED_LISTENERS` the 
      `kafka-console-consumer` attempts to connect to `localhost:9092` with your original bind address `broker-1:9092`
      and this failed.
   2. The `CLI` fixes this by advertising to the `broker-1` host instead of the `localhost` (that works perfectly fine 
      for clients that reside on the host-side). As every listener needs its own port CLI is configured to use 9094 
      instead of `9092`
   3. Moreover, changing `CLIENT://broker-1:9092` to `CLIENT://0.0.0.0:9092` in the `KAFKA_LISTENERS` list of 
      [../docker-compose-tls.yml](../docker-compose-tls.yml) is sufficient to make these work as well:
      ```bash
      docker exec -it broker-1 kafka-console-consumer \
        --bootstrap-server localhost:9092 \
        --topic basic-topic \
        --command-config /etc/kafka/secrets/client-ssl.properties \
        --from-beginning
      ```
      and
      ```bash
      docker exec -it broker-1 kafka-console-consumer \
        --bootstrap-server broker-1:9092 \
        --topic basic-topic \
        --command-config /etc/kafka/secrets/client-ssl.properties \
        --from-beginning
      ```
      still the separate `CLI` listener is the cleanest option.

### Troubleshooting
Many things can go wrong
- Some typo in your docker-compose configuration can mess up the whole thing. We took care of that in our
  [../docker-compose-tls.yml](../docker-compose-tls.yml), but when you try to recreate things in your own project, the
  compose yaml is the first thing to check. (see ... for a detailed explanation of our docker compose configuration)
- Something could go wrong in your keystore and truststore setup, but if you followed our instruction closely and used 
  the available scripts, it should work fine. Again adapting the procedure in your own projects may easily introduce
  faults. So make sure you understand the purpose of each step, before venturing out in your own project.

#### Diagnostics
   1. you could rerun both clients after changing `DEBUG_SSL_HANDSHAKE=true` in your `.env` file.
   2. look into the log of the Kafka `broker-1` Docker container
   3. open an interactive bash session into the Kafka `broker-1` Docker container
   4. check TLS config of kafka cluster with `openssl`

#### ad 3. open an interactive bash session into the Kafka `broker-1` Docker container
- `docker exec -it broker-1 bash`
- Then you can check if the PKI artifacts were passed into the container properly through the docker compose volumes
  definition:
  - `[appuser@broker-1 ~]$ cd /etc/kafka/secrets`
  - `[appuser@broker-1 secrets]$ ls -la`
- When you see that `broker-1.keystore.jks`, most important for the proper TLS encryption and this stage of development,
  you can check its contents with `keytool -list -keystore broker-1.keystore.jks` (or with the `-v` flag for more 
  verbose feedback). You are prompted for a password, that should be the same one you used creating the keystore and 
  is also configured in [../docker-compose-tls.yml](../docker-compose-tls.yml) to both `KAFKA_SSL_KEYSTORE_PASSWORD` and
  `KAFKA_SSL_KEY_PASSWORD`.
- You can do the same for `kafka.truststore.jks`, which is not used by the broker at this stage, but by the Kafka CLI 
  - `kafka-console-producer` &
  - `kafka-console-consumer`
- And check the contents of `client-ssl.properties`, also used by the Kafka CLI clients with:

  `cat client-ssl.properties`  

#### ad 4. check TLS config of kafka cluster from the docker host with `openssl`
- Our Java 
  [`nl.vea.kafka.security.encryption.BasicSSLConsumer`](../src/main/java/nl/vea/kafka/security/encryption/BasicSSLConsumer.java)
  and
  [`nl.vea.kafka.security.encryption.BasicSSLProducer`](../src/main/java/nl/vea/kafka/security/encryption/BasicSSLProducer.java)
  applications both rely on the Kafka cluster to have configured their keystore properly and as a result issuing the 
  right TLS certificate information in every call to a broker.
- We can test this with `openssl` connecting to `localhost:9092`, which is the same address our Java client applications
  are configured to use, and asking for the certificate signing chain:
- `openssl s_client -showcerts -connect localhost:9092 > openssl_connection_test.txt`
- This writes the content to the openssl_connection_test.txt.
- You should see the broker-1 certificate first, identified by the dn of the subject (owner) and the issuer, who signed it:
  ```bash
  0 s:C=NL, ST=., L=Amersfoort, O=ZLence, OU=Training, CN=broker-1
    i:C=NL, ST=Overijssel, L=Aadorp, O=Ons Bedrijf, OU=Training, CN=Kafka-CA, emailAddress=jan.jansen@ons-bedrijf.nl 
  ```
- Then you see our fake CA certificate, the issuer of the previous one identified by:
  ```bash
  1 s:C=NL, ST=Overijssel, L=Aadorp, O=Ons Bedrijf, OU=Training, CN=Kafka-CA, emailAddress=jan.jansen@ons-bedrijf.nl
    i:C=NL, ST=Overijssel, L=Aadorp, O=Ons Bedrijf, OU=Training, CN=Kafka-CA, emailAddress=jan.jansen@ons-bedrijf.nl
  ```
- You can also see the complete Base64 encoded content of both certificates. You can use this in other scenario's
  where you are developing the client application that needs to connect to a remote server by copying the content of a 
  root certificate, obtained in this way into a new `.pem` file and import that file into your client's truststore.

## Not an airtight configuration yet
The current configuration of [`../docker-compose-tls.yml`](../docker-compose-tls.yml) leaves room for the Kafka CLI 
clients to bypass the TLS encryption by connecting to `broker-1:29092` instead of `broker-1:9092`.
As a matter of fact we still use this in our [`../create-topic.sh`](../create-topic.sh) script.
```bash
docker exec -it broker-1 kafka-console-consumer \
  --bootstrap-server broker-1:29092 \
  --topic basic-topic \
  --from-beginning
```
Also still works without using the TLS encryption. The only way to fix it is to make the protocol of the `BROKER`
listener `SSL` as well or even `SASL_SSL`. But that is for a later session.

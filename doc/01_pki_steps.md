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

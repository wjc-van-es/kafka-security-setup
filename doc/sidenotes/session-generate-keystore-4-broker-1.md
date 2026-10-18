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

# Session generating keystore for `broker-1`

## session details

<details>

```bash
(base) willem@mint-22:~/git/kafka-security-setup/tls$ ./generate-keystore.sh broker-1
Commencing keystores/broker-1.keystore.jks generation...
containing a key / certificate pair with DN=CN=broker-1, OU=Training, O=ZLence, L=Amersfoort, ST=., C=NL and SAN=DNS:broker-1,DNS:localhost,IP:127.0.0.1
Generating 3072-bit RSA key pair and self-signed certificate (SHA384withRSA) with a validity of 3,650 days
        for: CN=broker-1, OU=Training, O=ZLence, L=Amersfoort, ST=., C=NL
Generation of keystores/broker-1.keystore.jks completed.
Commencing broker-1.csr generation...
Generation of broker-1.csr completed.
Commencing broker-1.signed-cert.pem generation by signing broker-1.csr with ca-cert.pem...
Certificate request self-signature ok
subject=C=NL, ST=., L=Amersfoort, O=ZLence, OU=Training, CN=broker-1
Generation of broker-1.signed-cert.pem completed.
Commencing import of ca-cert.pem into keystores/broker-1.keystore.jks...
Owner: EMAILADDRESS=jan.jansen@ons-bedrijf.nl, CN=Kafka-CA, OU=Training, O=Ons Bedrijf, L=Aadorp, ST=Overijssel, C=NL
Issuer: EMAILADDRESS=jan.jansen@ons-bedrijf.nl, CN=Kafka-CA, OU=Training, O=Ons Bedrijf, L=Aadorp, ST=Overijssel, C=NL
Serial number: 5c9c34fd40e35ffdd7750247b4f383f6386f9819
Valid from: Sun Oct 04 17:07:06 CEST 2026 until: Wed Oct 01 17:07:06 CEST 2036
Certificate fingerprints:
         SHA1: 70:45:0C:C0:A5:60:97:A4:CF:A2:07:56:53:80:CD:80:64:C3:67:A6
         SHA256: 0C:03:BA:3E:4F:C9:3C:CB:9A:59:72:22:6C:4A:DA:B1:90:8E:9E:E4:D3:DD:9D:54:4E:E2:5F:81:70:E6:FF:BA
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions: 

#1: ObjectId: 2.5.29.35 Criticality=false
AuthorityKeyIdentifier [
KeyIdentifier [
0000: B0 F0 5D 0B B2 2E B4 C1   94 A0 5B 71 57 D5 13 FA  ..].......[qW...
0010: 52 43 49 3F                                        RCI?
]
]

#2: ObjectId: 2.5.29.19 Criticality=true
BasicConstraints:[
  CA:true
  PathLen: no limit
]

#3: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: B0 F0 5D 0B B2 2E B4 C1   94 A0 5B 71 57 D5 13 FA  ..].......[qW...
0010: 52 43 49 3F                                        RCI?
]
]

Trust this certificate? [no]:  y
Certificate was added to keystore
Import of ca-cert.pem into keystores/broker-1.keystore.jks completed.
Commencing import broker-1.signed-cert.pem into keystores/broker-1.keystore.jks...
Certificate reply was installed in keystore
Import broker-1.signed-cert.pem into keystores/broker-1.keystore.jks completed.
(base) willem@mint-22:~/git/kafka-security-setup/tls$ keytool -list -v -keystore keystores/broker-1.keystore.jks 
Enter keystore password:  
Keystore type: PKCS12
Keystore provider: SUN

Your keystore contains 2 entries

Alias name: broker-1
Creation date: Oct 5, 2026
Entry type: PrivateKeyEntry
Certificate chain length: 2
Certificate[1]:
Owner: CN=broker-1, OU=Training, O=ZLence, L=Amersfoort, ST=., C=NL
Issuer: EMAILADDRESS=jan.jansen@ons-bedrijf.nl, CN=Kafka-CA, OU=Training, O=Ons Bedrijf, L=Aadorp, ST=Overijssel, C=NL
Serial number: 2bca7a338f0ee0ed5011ba419a84847fd632e79f
Valid from: Mon Oct 05 23:27:40 CEST 2026 until: Thu Oct 02 23:27:40 CEST 2036
Certificate fingerprints:
         SHA1: D9:87:E2:E5:4F:65:2C:1D:E5:91:97:F9:35:E3:DE:87:50:99:8C:1C
         SHA256: 7D:3D:3C:8D:AB:75:A1:49:8B:4E:A7:41:FA:58:73:30:BD:97:3B:D2:BD:EC:BC:93:1C:7D:EE:A5:B7:9A:CB:F0
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 3072-bit RSA key
Version: 3

Extensions: 

#1: ObjectId: 2.5.29.35 Criticality=false
AuthorityKeyIdentifier [
KeyIdentifier [
0000: B0 F0 5D 0B B2 2E B4 C1   94 A0 5B 71 57 D5 13 FA  ..].......[qW...
0010: 52 43 49 3F                                        RCI?
]
]

#2: ObjectId: 2.5.29.19 Criticality=false
BasicConstraints:[
  CA:false
  PathLen: undefined
]

#3: ObjectId: 2.5.29.15 Criticality=false
KeyUsage [
  DigitalSignature
  Non_repudiation
  Key_Encipherment
  Data_Encipherment
]

#4: ObjectId: 2.5.29.17 Criticality=false
SubjectAlternativeName [
  DNSName: broker-1
  DNSName: localhost
  IPAddress: 127.0.0.1
]

#5: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: 6C 62 CA EB D0 93 9B 99   A7 B8 11 03 AB D3 7F 21  lb.............!
0010: 45 3F B6 4C                                        E?.L
]
]

Certificate[2]:
Owner: EMAILADDRESS=jan.jansen@ons-bedrijf.nl, CN=Kafka-CA, OU=Training, O=Ons Bedrijf, L=Aadorp, ST=Overijssel, C=NL
Issuer: EMAILADDRESS=jan.jansen@ons-bedrijf.nl, CN=Kafka-CA, OU=Training, O=Ons Bedrijf, L=Aadorp, ST=Overijssel, C=NL
Serial number: 5c9c34fd40e35ffdd7750247b4f383f6386f9819
Valid from: Sun Oct 04 17:07:06 CEST 2026 until: Wed Oct 01 17:07:06 CEST 2036
Certificate fingerprints:
         SHA1: 70:45:0C:C0:A5:60:97:A4:CF:A2:07:56:53:80:CD:80:64:C3:67:A6
         SHA256: 0C:03:BA:3E:4F:C9:3C:CB:9A:59:72:22:6C:4A:DA:B1:90:8E:9E:E4:D3:DD:9D:54:4E:E2:5F:81:70:E6:FF:BA
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions: 

#1: ObjectId: 2.5.29.35 Criticality=false
AuthorityKeyIdentifier [
KeyIdentifier [
0000: B0 F0 5D 0B B2 2E B4 C1   94 A0 5B 71 57 D5 13 FA  ..].......[qW...
0010: 52 43 49 3F                                        RCI?
]
]

#2: ObjectId: 2.5.29.19 Criticality=true
BasicConstraints:[
  CA:true
  PathLen: no limit
]

#3: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: B0 F0 5D 0B B2 2E B4 C1   94 A0 5B 71 57 D5 13 FA  ..].......[qW...
0010: 52 43 49 3F                                        RCI?
]
]



*******************************************
*******************************************


Alias name: ca-root
Creation date: Oct 5, 2026
Entry type: trustedCertEntry

Owner: EMAILADDRESS=jan.jansen@ons-bedrijf.nl, CN=Kafka-CA, OU=Training, O=Ons Bedrijf, L=Aadorp, ST=Overijssel, C=NL
Issuer: EMAILADDRESS=jan.jansen@ons-bedrijf.nl, CN=Kafka-CA, OU=Training, O=Ons Bedrijf, L=Aadorp, ST=Overijssel, C=NL
Serial number: 5c9c34fd40e35ffdd7750247b4f383f6386f9819
Valid from: Sun Oct 04 17:07:06 CEST 2026 until: Wed Oct 01 17:07:06 CEST 2036
Certificate fingerprints:
         SHA1: 70:45:0C:C0:A5:60:97:A4:CF:A2:07:56:53:80:CD:80:64:C3:67:A6
         SHA256: 0C:03:BA:3E:4F:C9:3C:CB:9A:59:72:22:6C:4A:DA:B1:90:8E:9E:E4:D3:DD:9D:54:4E:E2:5F:81:70:E6:FF:BA
Signature algorithm name: SHA256withRSA
Subject Public Key Algorithm: 2048-bit RSA key
Version: 3

Extensions: 

#1: ObjectId: 2.5.29.35 Criticality=false
AuthorityKeyIdentifier [
KeyIdentifier [
0000: B0 F0 5D 0B B2 2E B4 C1   94 A0 5B 71 57 D5 13 FA  ..].......[qW...
0010: 52 43 49 3F                                        RCI?
]
]

#2: ObjectId: 2.5.29.19 Criticality=true
BasicConstraints:[
  CA:true
  PathLen: no limit
]

#3: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: B0 F0 5D 0B B2 2E B4 C1   94 A0 5B 71 57 D5 13 FA  ..].......[qW...
0010: 52 43 49 3F                                        RCI?
]
]



*******************************************
*******************************************


(base) willem@mint-22:~/git/kafka-security-setup/tls$ 
```

</details>
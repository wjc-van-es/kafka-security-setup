#!/usr/bin/env bash

# in real life you would keep your password secret and not a part of an artefact stored in a git repository
declare PASSWORD=changeit
declare DN="CN=kafka-cluster, OU=Training, O=ZLence, L=Amersfoort, ST=Utrecht, C=NL"

# in real life it would be safer not to use the -storepass $PASSWORD -noprompt arguments and instead let the
# command prompt for your secret password

# keytool is part of the JDK, if you have multiple versions installed (e.g. with SDKMan!) check in your terminal, which
# one you are running:
# java -XshowSettings:properties --version
# or with SDKMan!
# sdk current java
# change when needed with SDKMan!:
# sdk use java 25.0.3-tem
keytool -keystore broker-1.keystore.jks -alias kafka-cluster -genkey -keyalg RSA \
-storetype pkcs12 -storepass $PASSWORD -keypass $PASSWORD \
-dname "$DN" -ext SAN=DNS:localhost,DNS:broker-1,IP:127.0.0.1 2>/dev/null
#!/usr/bin/env bash

# in real life you would keep your password secret and not a part of an artefact stored in a git repository
declare -r PASSWORD=changeit
declare -r CA_ALIAS="ca-root"
declare -r KEYSTORE_PATH="keystores/kafka.truststore.jks" # path relative to this script's location

# in real life it would be safer not to use the -storepass $PASSWORD -noprompt arguments and instead let the
# command prompt for your secret password

# keytool is part of the JDK, if you have multiple versions installed (e.g. with SDKMan!) check in your terminal, which
# one you are running:
# java -XshowSettings:properties --version
# or with SDKMan!
# sdk current java
# change when needed with SDKMan!:
# sdk use java 25.0.3-tem
keytool -keystore $KEYSTORE_PATH -alias $CA_ALIAS -import -file ca-cert.pem \
-storepass $PASSWORD -noprompt

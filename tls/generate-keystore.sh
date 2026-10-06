#!/usr/bin/env bash

# keytool is part of the JDK, if you have multiple versions installed (e.g. with SDKMan!) check in your terminal, which
# one you are running:
# java -XshowSettings:properties --version
# or with SDKMan!
# sdk current java
# change when needed with SDKMan!:
# sdk use java 25.0.3-tem
# in real life you would keep your password secret and not a part of an artefact stored in a git repository
declare -r PASSWORD=changeit
declare CN="broker-1"
declare -r OU="Training"
declare -r O="ZLence"
declare -r L="Amersfoort"
declare -r ST="."
declare -r C="NL"

# take the name of the topic from the first argument if present
if [ -n "$1" ]
then
  CN=$1
fi

# shellcheck disable=SC2290
declare -r KEYSTORE_PATH="keystores/$CN.keystore.jks" # path relative to this script's location
declare -r DN="CN=$CN, OU=$OU, O=$O, L=$L, ST=$ST, C=$C"
declare -r SAN="DNS:$CN,DNS:localhost,IP:127.0.0.1"
declare -r CA_ALIAS="ca-root"
declare -r CA_CERT_FILE="ca-cert.pem"
declare -r CA_KEY_FILE="ca-key.pem"
declare -r CSR_FILE="$CN.csr"
declare -r SIGNED_CSR_FILE="$CN.signed-cert.pem"
declare -r VALIDITY_DAYS=3650 # will last 10 years

# Generate a keystore for the broker specified with CN with a key / certificate pair
# in real life it would be safer not to use the -storepass $PASSWORD -noprompt arguments and instead let the
# command prompt for your secret password
# 2>/dev/null will redirect sterr output to /dev/null to get rid of it without display
echo "Commencing $KEYSTORE_PATH generation..."
echo "containing a key / certificate pair with DN=$DN and SAN=$SAN"
keytool -keystore $KEYSTORE_PATH -alias $CN -genkey -keyalg RSA \
-storetype pkcs12 -storepass $PASSWORD -keypass $PASSWORD -validity $VALIDITY_DAYS \
-dname "$DN" -ext "SAN=$SAN"
wait
echo "Generation of $KEYSTORE_PATH completed."

# Generate Certificate Signing Request (CSR) using the newly created KeyStore
echo "Commencing $CSR_FILE generation..."
keytool -certreq -keystore $KEYSTORE_PATH -alias $CN -file $CSR_FILE \
-storepass $PASSWORD -ext "SAN=$SAN"
wait
echo "Generation of $CSR_FILE completed."

# Sign the CSR using the custom CA
# the content of -extfile is created dynamically to account for the potentially variable value of $CN
echo "Commencing $SIGNED_CSR_FILE generation by signing $CSR_FILE with $CA_CERT_FILE..."
openssl x509 -req -CA $CA_CERT_FILE -CAkey $CA_KEY_FILE -in $CSR_FILE -out $SIGNED_CSR_FILE \
-days $VALIDITY_DAYS -CAcreateserial -extfile <(cat <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $CN
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF
)
wait
echo "Generation of $SIGNED_CSR_FILE completed."

# Import ROOT CA certificate into Keystore
echo "Commencing import of $CA_CERT_FILE into $KEYSTORE_PATH..."
keytool -importcert -keystore $KEYSTORE_PATH -alias $CA_ALIAS -file $CA_CERT_FILE -storepass $PASSWORD
wait
echo "Import of $CA_CERT_FILE into $KEYSTORE_PATH completed."

# Import newly signed certificate into Keystore
echo "Commencing import $SIGNED_CSR_FILE into $KEYSTORE_PATH..."
keytool -importcert -keystore $KEYSTORE_PATH -alias $CN -file $SIGNED_CSR_FILE -storepass $PASSWORD
wait
echo "Import $SIGNED_CSR_FILE into $KEYSTORE_PATH completed."

# Clean-up is convenient if you want to make several keystores in a row (for multiple brokers)
# Comment out when you want to debug your proces by validating these artifacts
# But don't forget to delete them by hand before going on to the next broker
# rm $CSR_FILE
# rm $SIGNED_CSR_FILE
# rm $CA_CERT_FILE.srl
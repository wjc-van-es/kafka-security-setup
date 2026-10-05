#!/usr/bin/env bash

VALIDITY_DAYS=3650 # will last 10 years
CA_KEY_FILE="ca-key.pem"
CA_CERT_FILE="ca-cert.pem"
SUBJECT="/C=NL/ST=Overijssel/L=Aadorp/O=Ons Bedrijf/OU=Training/CN=Kafka-CA/emailAddress=jan.jansen@ons-bedrijf.nl"

openssl req -new -x509 -keyout $CA_KEY_FILE -out $CA_CERT_FILE -days $VALIDITY_DAYS \
-nodes -subj "$SUBJECT"

# -nodes argument stands for "no DES encryption" to prevent the generated $CA_KEY_FILE being encrypted with a passphrase.
# This should not be used for real production situations, but is convenient for turorials like this one.
# -subj can take the distinguished name (dn) where each part is separated by a slash

#### if you omit -nodes you will be prompted for a passphrase with which the private key then will be encrypted ####
# Passphrase: password

#### if you omit -subj you will be prompted for the following parts of the dn ####
# Country Name: NL
# State or Province: Overijssel
# City: Aadorp
# Organization Name: Ons Bedrijf
# Organizational Unit Name: Training
# Common Name: Kafka-CA
# Email: jan.jansen@ons-bedrijf.nl
<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# For a demo application we created our own ca key \& certificate with openssl

we now have to sign a csr file of a certificate with as SAN=DNS:localhost,IP:127.0.0.1
we use

```bash
openssl x509 -req -CA $CA_CERT_FILE -CAkey $CA_KEY_FILE -in $CN.csr -out $CN.signed \
-days $VALIDITY_DAYS -CAcreateserial -extfile v3.ext
```

For the content of the v3.ext we want to use

```
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1

```

I am not sure about the entry IP.1 = 127.0.0.1 Is the syntax correct?

Yes, the syntax in your `v3.ext` file is correct. The line `IP.1 = 127.0.0.1` under the `[alt_names]` section is the proper way to specify an IP address Subject Alternative Name (SAN) when using a named section reference like `subjectAltName = @alt_names`.[^1_1][^1_2][^1_3]

## How it works

When you use `subjectAltName = @alt_names`, OpenSSL expects a section called `[alt_names]` containing indexed entries. Each entry uses the format `TYPE.N = value`, where:

- `TYPE` is one of: `DNS`, `IP`, `URI`, `email`, `RID`, `dirName`, or `otherName`
- `N` is a sequential number (1, 2, 3, ...)
- `value` is the actual identifier[^1_2][^1_1]

So your configuration is valid:

```ini
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
```

This will produce a certificate with SAN containing both `DNS:localhost` and `IP:127.0.0.1`.[^1_4][^1_5]

## Alternative inline syntax

If you prefer not to use a named section, you can also specify the SAN inline in the extension file:

```ini
subjectAltName = DNS:localhost,IP:127.0.0.1
```

Both approaches are equivalent and supported by OpenSSL.[^1_6][^1_7][^1_8]

## Verification

After signing the certificate, you can verify the SANs are present with:

```bash
openssl x509 -in $CN.signed -noout -ext subjectAltName
```

This should output something like:

```
X509v3 Subject Alternative Name:
    DNS:localhost, IP Address:127.0.0.1
```

<span style="display:none">[^1_10][^1_11][^1_12][^1_13][^1_14][^1_15][^1_9]</span>

<div align="center">⁂</div>

[^1_1]: https://www.openssl.org/docs/man1.0.2/man5/x509v3_config.html

[^1_2]: https://docs.openssl.org/3.0/man5/x509v3_config/

[^1_3]: https://docs.openssl.org/3.1/man5/x509v3_config/

[^1_4]: https://helm.sh/docs/v2/using_helm/tiller_ssl/

[^1_5]: https://manual.keyshot.com/keyshot11/manual/getting-started/setup/manager-setup/get-a-tls-certificate/

[^1_6]: https://docs.opensearch.org/3.3/security/configuration/generate-certificates/

[^1_7]: https://docs.opensearch.org/latest/security/configuration/generate-certificates/

[^1_8]: https://docs.openssl.org/master/man5/x509v3_config/

[^1_9]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/deployment_guide/sssd-ldap-domain-ip

[^1_10]: https://docs.openssl.org/3.2/man1/openssl-x509/

[^1_11]: https://docs.openssl.org/3.0/man1/openssl-x509/

[^1_12]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/5/html/deployment_guide/sssd-ldap-domain-ip

[^1_13]: https://www.osso.nl/blog/2020/openssl-sign-subject-alternative-names/

[^1_14]: https://github.com/pion/dtls/blob/master/examples/certificates/README.md

[^1_15]: https://gist.github.com/elklein96/a15090f35a41e16bdc8574a7fb81e119


---

# Just for verification:

The key / certificate pair will be used by a kafka broker that lives in a docker cluster created with docker compose within the docker internal network it will suffice when the CN of the certificate has the name of the services.broker-n.hostname value as defined in the docker-compose.yml file. Clients outside the docker cluster (but on the same machine) can make a TLS connection because SAN=DNS:localhost,IP:127.0.0.1 was defined for the certificate. Right?

Your understanding is **mostly correct**, but there are some important nuances depending on how your clients connect and whether hostname verification is enabled.[^2_1][^2_2][^2_3]

## Docker-internal clients (service-to-service)

✅ **Correct**: If clients inside the Docker network connect using the service name (e.g., `broker-n` or `broker-n.hostname` as defined in `../../docker-compose-plain.yml`), the certificate must have that name in either the **CN** or **SAN**.[^2_4][^2_5][^2_6]

However, **best practice is to use SAN, not CN**. While Kafka will check both fields, CN-based hostname verification has been deprecated since 2000, and SAN is more flexible and RFC-2818 compliant.[^2_2][^2_7][^2_1]

For your setup, the broker certificate should include:

- `DNS:broker-n` (the Docker service name)
- `DNS:broker-n.hostname` (if that's the FQDN clients use)
- Potentially `DNS:broker-n.<network>` depending on your Docker DNS resolution

[^2_8][^2_4]

## External clients on the same host

✅ **Correct**: Clients on the host machine connecting via `localhost` or `127.0.0.1` will succeed **if** the certificate has `SAN=DNS:localhost,IP:127.0.0.1`.[^2_3][^2_9]

## Critical considerations

### 1. Hostname verification behavior

By default (Kafka 2.0+), clients perform hostname verification and will check the broker's certificate against the hostname they're connecting to.[^2_10][^2_11][^2_1]

- If a client connects to `broker-n:9093`, it expects `DNS:broker-n` in the certificate
- If a client connects to `localhost:9093`, it expects `DNS:localhost` or `IP:127.0.0.1` in the certificate

[^2_9][^2_8]

### 2. Multiple SANs for multiple access patterns

Since you have **both** internal Docker clients and external localhost clients, your broker certificate should include **all** the names clients might use:

```ini
subjectAltName = @alt_names

[alt_names]
DNS.1 = broker-n
DNS.2 = broker-n.hostname
DNS.3 = localhost
IP.1 = 127.0.0.1
```


### 3. Advertised listeners configuration

Ensure your Kafka broker's `advertised.listeners` matches the certificate SANs. If the broker advertises `broker-n:9093` but clients connect to `localhost:9093`, you may encounter mismatches.[^2_5][^2_6][^2_12]

## Summary

| Client location | Connects via | Certificate requirement |
| :-- | :-- | :-- |
| Inside Docker network | `broker-n:9093` | `DNS:broker-n` in SAN (or CN) |
| Host machine | `localhost:9093` | `DNS:localhost` in SAN |
| Host machine | `127.0.0.1:9093` | `IP:127.0.0.1` in SAN |

[^2_6][^2_1][^2_9]

If you want a single certificate to work for all scenarios, include **all relevant DNS names and IPs** in the SAN extension. Relying only on CN is possible but not recommended for production or security-conscious setups.[^2_7][^2_2][^2_8]

<span style="display:none">[^2_13][^2_14][^2_15]</span>

<div align="center">⁂</div>

[^2_1]: https://kafka.apache.org/43/security/encryption-and-authentication-using-ssl/

[^2_2]: https://kafka.apache.org/41/security/encryption-and-authentication-using-ssl/

[^2_3]: https://kafka.apache.org/42/security/encryption-and-authentication-using-ssl/

[^2_4]: https://docs.confluent.io/operator/1.6/co-authenticate.html

[^2_5]: https://docs.redhat.com/en/documentation/red_hat_streams_for_apache_kafka/2.8/html/using_streams_for_apache_kafka_on_rhel_in_kraft_mode/assembly-securing-kafka-str

[^2_6]: https://www.conduktor.io/glossary/mtls-for-kafka

[^2_7]: https://kafka.apache.org/10/security/encryption-and-authentication-using-ssl/

[^2_8]: https://kafka.unisbadri.com/en/security/certificate-and-key-management/

[^2_9]: https://algomaster.io/learn/kafka/tls-and-encryption-in-transit

[^2_10]: https://kafka.apache.org/32/security/encryption-and-authentication-using-ssl/

[^2_11]: https://developer.confluent.io/courses/security/authentication-ssl-and-sasl-ssl/

[^2_12]: https://discuss.elastic.co/t/setting-filebeat-5-with-kafka-0-10-over-tls/59550/2

[^2_13]: https://kafka.apache.org/39/security/encryption-and-authentication-using-ssl/

[^2_14]: https://docs.redhat.com/en/documentation/red_hat_streams_for_apache_kafka/3.0/html/deploying_and_managing_streams_for_apache_kafka_on_openshift/assembly-securing-access-str

[^2_15]: https://code.kx.com/insights/1.3/extras/kafka-tls-setup.html


---

# I have a flexible bash script file were are create artifacts like a keystore, csr and do the signing and importing of the signed certificate based on a variable broker hostname (as \$CN). Is there a way to use that variable inside the v3.ext I use in the openssl signing command with -extfile v3.ext?

Yes, you can use the `$CN` variable in your `v3.ext` file, but **not directly**. OpenSSL's `-extfile` doesn't perform shell variable expansion. You have three practical options:[^3_1][^3_2][^3_3]

## Option 1: Use process substitution (recommended for bash)

Instead of a static `v3.ext` file, generate the extension content dynamically using bash process substitution:

```bash
openssl x509 -req -CA $CA_CERT_FILE -CAkey $CA_KEY_FILE \
  -in $CN.csr -out $CN.signed \
  -days $VALIDITY_DAYS -CAcreateserial \
  -extfile <(cat <<EOF
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
```

This creates a temporary file descriptor that OpenSSL reads, with `$CN` expanded by bash.[^3_3][^3_4][^3_5]

## Option 2: Generate the extfile dynamically

Create the `v3.ext` file on-the-fly before the signing command:

```bash
cat > v3.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $CN
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

openssl x509 -req -CA $CA_CERT_FILE -CAkey $CA_KEY_FILE \
  -in $CN.csr -out $CN.signed \
  -days $VALIDITY_DAYS -CAcreateserial \
  -extfile v3.ext
```


## Option 3: Use environment variables (OpenSSL 1.1.0+)

OpenSSL can read environment variables using the `${ENV::VAR}` syntax in config files:

```ini
# v3.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${ENV::CN}
DNS.2 = localhost
IP.1 = 127.0.0.1
```

Then run:

```bash
export CN=$CN
openssl x509 -req -CA $CA_CERT_FILE -CAkey $CA_KEY_FILE \
  -in $CN.csr -out $CN.signed \
  -days $VALIDITY_DAYS -CAcreateserial \
  -extfile v3.ext
```


## Recommendation

**Option 1 (process substitution)** is cleanest for scripts—it avoids creating temporary files and keeps everything in one command. **Option 2** is more portable if you need to support shells without process substitution.[^3_4][^3_5][^3_6]

<span style="display:none">[^3_10][^3_11][^3_12][^3_13][^3_14][^3_15][^3_7][^3_8][^3_9]</span>

<div align="center">⁂</div>

[^3_1]: https://docs.openssl.org/3.6/man1/openssl-x509/

[^3_2]: https://docs.openssl.org/3.5/man1/openssl-x509/

[^3_3]: https://mta.openssl.org/pipermail/openssl-users/2022-May/015198.html

[^3_4]: https://developer.harness.io/web-application-and-api-protection-waap/installation/optional-installation-topics/generate-self-signed-certificate

[^3_5]: https://stackoverflow.com/questions/6194236/openssl-certificate-version-3-with-subject-alternative-name

[^3_6]: https://stackoverflow.com/questions/59579759/how-to-dynamically-generate-extfile-parameter-for-openssl-in-bash-script

[^3_7]: https://docs.openssl.org/1.1.1/man1/x509/

[^3_8]: https://docs.openssl.org/master/man1/openssl-x509/

[^3_9]: https://docs.openssl.org/1.0.2/man1/x509/

[^3_10]: https://knowledge.broadcom.com/external/article/57521/generating-client-certificates-with-subj.html

[^3_11]: https://docs.openssl.org/3.6/man1/openssl-req/

[^3_12]: https://docs.openssl.org/3.5/man1/openssl-req/

[^3_13]: https://security.stackexchange.com/questions/74345/provide-subjectaltname-to-openssl-directly-on-the-command-line

[^3_14]: https://docs.openssl.org/3.0/man1/openssl-x509/

[^3_15]: https://docs.openssl.org/3.2/man1/openssl-x509/


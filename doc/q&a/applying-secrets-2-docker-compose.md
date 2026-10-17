<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# I would like to use secrets in a docker compose file where one of the services defines a kafka broker container based on the image confluentinc/cp-kafka:8.2.0

In [https://docs.docker.com/compose/how-tos/use-secrets/](https://docs.docker.com/compose/how-tos/use-secrets/) I read that I can store passwords in ordinary text files, presumably in the same directory where the docker-compose.yml file is. However, It doesn't work.
When I change back the passwords to literal values in my docker-compose.yml file, but I keep the top level secrets entries. Now the container at least keeps running. When I start an interactive session I can find the `/run` directory, but there is no `/run/secrets` directory. So the text fiels are not passed into my container. What gives?

The likely issue is that you declared the secrets only in the **top-level** `secrets:` section. That defines them, but does **not** give any container access to them. Each service that needs one must also list it under that service’s own `secrets:` key; only then Compose bind-mounts it at `/run/secrets/<name>`.[^1_1][^1_2]

## Correct Compose structure

```yaml
services:
  kafka:
    image: confluentinc/cp-kafka:8.2.0
    secrets:
      - kafka_sasl_password
      - kafka_controller_password
    environment:
      KAFKA_PROCESS_ROLES: broker,controller
      # ...other Kafka settings...

secrets:
  kafka_sasl_password:
    file: ./secrets/kafka_sasl_password.txt
  kafka_controller_password:
    file: ./secrets/kafka_controller_password.txt
```

With this form, inside the Kafka container you should find:

```text
/run/secrets/kafka_sasl_password
/run/secrets/kafka_controller_password
```

The top-level declaration alone is intentionally not enough: Compose explicitly requires a per-service `secrets` grant.[^1_2][^1_3]

## Check these details

- Use `docker compose config` to validate the resolved Compose file; it should show the service-level `secrets` entries.
- Relative `file:` paths are resolved relative to the Compose file’s directory.[^1_3]
- Avoid a trailing newline unless you intend it to be part of the password; create files with `printf '%s' 'secret' > secrets/kafka_sasl_password.txt` rather than many editors’ default newline-adding save behavior.
- Recreate the container after changing secret grants: `docker compose up -d --force-recreate kafka`. An existing container will not gain a new bind mount merely by editing the YAML.
- Compose runtime secrets are for Linux containers; they are delivered as single-file bind mounts.[^1_1]


## Important cp-kafka caveat

Mounting `/run/secrets/...` does **not** automatically make Confluent’s Kafka image consume those values. The cp-kafka image primarily turns `KAFKA_*` environment variables into Kafka broker properties; it does not generally implement the common `*_FILE` secret-file convention.[^1_4][^1_5]

So this alone will not configure Kafka:

```yaml
environment:
  KAFKA_SASL_PASSWORD: /run/secrets/kafka_sasl_password   # usually wrong
```

For a Kafka broker, the password often has to end up inside a JAAS/LDAP/SASL configuration value rather than a standalone environment variable. Practical options are:

1. **Use an entrypoint wrapper** that reads the mounted secret and exports the required `KAFKA_*` variable before invoking the image’s original entrypoint.
2. **Generate the broker JAAS/config file** from `/run/secrets/*` in an init container or wrapper script, then point Kafka at that generated file.
3. If your secret is acceptable as an environment value, use Compose’s `secrets.<name>.environment:` source and inject it into the required `KAFKA_*` variable—but note that this puts the value into the container environment, which is weaker isolation than a mounted file.[^1_3]

A minimal wrapper pattern is:

```yaml
services:
  kafka:
    image: confluentinc/cp-kafka:8.2.0
    entrypoint:
      - /bin/bash
      - -c
      - |
        export KAFKA_SOME_PASSWORD="$(cat /run/secrets/kafka_sasl_password)"
        exec /etc/confluent/docker/run
    secrets:
      - kafka_sasl_password
```

Use the actual `KAFKA_*` property/name required by your chosen SASL or authentication mechanism; the exact variable depends on the listener and security configuration you are using.

In short: add `secrets:` **under the Kafka service**, recreate the container, and then add a small wrapper or config-generation step because `cp-kafka` will not read secret files by itself.[^1_2][^1_4]

<span style="display:none">[^1_10][^1_11][^1_12][^1_13][^1_14][^1_15][^1_6][^1_7][^1_8][^1_9]</span>

<div align="center">⁂</div>

[^1_1]: https://docs.docker.com/compose/how-tos/use-secrets.md

[^1_2]: https://docs.docker.com/reference/compose-file/services/

[^1_3]: https://docs.docker.com/reference/compose-file/secrets/

[^1_4]: https://docs.confluent.io/platform/current/installation/docker/config-reference.html

[^1_5]: https://docs.confluent.io/platform/7.4/installation/docker/config-reference.html

[^1_6]: https://docs.docker.com/engine/swarm/secrets.md

[^1_7]: https://docs.confluent.io/platform/current/tutorials/cp-demo/on-prem.md

[^1_8]: https://docs.confluent.io/cloud/current/cp-component/gateway/gateway-deploy.html

[^1_9]: https://www.okteto.com/docs/1.45/reference/docker-compose/

[^1_10]: https://www.okteto.com/docs/1.44/reference/docker-compose/

[^1_11]: https://lours.me/posts/compose-secrets-deep-dive-runtime-delivery/

[^1_12]: https://github.com/dockerwang/docker.github.io/blob/master/compose/compose-file/index.md

[^1_13]: https://github.com/confluentinc/mcp-confluent

[^1_14]: https://github.com/confluentinc/cp-demo/blob/7.5.1-post/docker-compose.yml

[^1_15]: https://docs.huihoo.com/apache/kafka/confluent/3.1/cp-docker-images/docs/tutorials/clustered-deployment-sasl.html


---

# So I forgot to add the secrets to the kfka broker service.

I added that and I can now see them as files in /run/secrets.
But assigning the content of these files to the available Confluent Kafka broker image environment variables still leads to the container starting up. (I could only check the files being passed in by using the old string literal assignment to
KAFKA_SSL_KEYSTORE_PASSWORD
KAFKA_SSL_KEY_PASSWORD and

That behavior is expected: `cp-kafka` does **not** read the contents of `/run/secrets/...` for you. If you set:

```yaml
KAFKA_SSL_KEYSTORE_PASSWORD: /run/secrets/kafka_ssl_keystore_password
```

then Kafka receives the literal string `/run/secrets/kafka_ssl_keystore_password` as the keystore password—not the file’s contents. The Confluent image converts `KAFKA_SSL_KEYSTORE_PASSWORD` into the broker property `ssl.keystore.password`, and `KAFKA_SSL_KEY_PASSWORD` into `ssl.key.password`; both must contain the actual password.[^2_1][^2_2][^2_3]

## Use an entrypoint wrapper

Read each secret file into the corresponding environment variable before starting Confluent’s normal entrypoint:

```yaml
services:
  kafka:
    image: confluentinc/cp-kafka:8.2.0
    entrypoint:
      - /bin/bash
      - -c
      - |
        set -euo pipefail
        export KAFKA_SSL_KEYSTORE_PASSWORD="$(cat /run/secrets/kafka_ssl_keystore_password)"
        export KAFKA_SSL_KEY_PASSWORD="$(cat /run/secrets/kafka_ssl_key_password)"
        exec /etc/confluent/docker/run
    environment:
      KAFKA_SSL_KEYSTORE_LOCATION: /etc/kafka/secrets/kafka.broker.keystore.jks
      # ...remaining non-secret Kafka configuration...
    volumes:
      - ./kafka-secrets:/etc/kafka/secrets:ro
    secrets:
      - kafka_ssl_keystore_password
      - kafka_ssl_key_password

secrets:
  kafka_ssl_keystore_password:
    file: ./secrets/kafka_ssl_keystore_password.txt
  kafka_ssl_key_password:
    file: ./secrets/kafka_ssl_key_password.txt
```

The `exec /etc/confluent/docker/run` part preserves the image’s normal startup behavior after the secrets have been exported. Docker Compose mounts each granted secret as a file under `/run/secrets/<secret-name>`; it does not transform it into an environment variable automatically.[^2_4][^2_5]

## Avoid newline problems

A trailing newline in the secret file becomes part of the exported value. Create the files without one:

```bash
mkdir -p secrets
printf '%s' 'your-keystore-password' > secrets/kafka_ssl_keystore_password.txt
printf '%s' 'your-key-password' > secrets/kafka_ssl_key_password.txt
```

Then recreate the Kafka service:

```bash
docker compose up -d --force-recreate kafka
```


## Verify inside the container

Do not print the secrets. Instead, verify that the environment variables contain the same number of characters as the secret files:

```bash
docker compose exec kafka bash -c \
  'printf "keystore=%s key=%s\n" \
    "$(printf %s "$KAFKA_SSL_KEYSTORE_PASSWORD" | wc -c)" \
    "$(printf %s "$KAFKA_SSL_KEY_PASSWORD" | wc -c)"'
```

If Kafka still exits immediately, inspect its logs:

```bash
docker compose logs kafka
```

A common remaining cause is that the keystore/key passwords are correct but the JKS/PKCS12 files, listener security protocol, or certificate aliases are misconfigured. The Confluent image expects the TLS settings to map to standard Kafka properties such as `ssl.keystore.location`, `ssl.keystore.password`, and `ssl.key.password`.[^2_2][^2_1]

## Alternative: Confluent secret protection

Confluent Platform also has a native “secrets protection” mechanism using `KAFKA_CONFIG_PROVIDERS` and `CONFLUENT_SECURITY_MASTER_KEY`, but it is more involved: you encrypt configuration values with Confluent tooling and configure a config provider for the broker. For just three TLS passwords, the entrypoint-wrapper approach is usually simpler.[^2_6][^2_7]

<span style="display:none">[^2_10][^2_11][^2_12][^2_13][^2_14][^2_15][^2_16][^2_8][^2_9]</span>

<div align="center">⁂</div>

[^2_1]: https://docs.confluent.io/platform/8.1/installation/docker/development.html

[^2_2]: https://docs.confluent.io/platform/7.6/kafka/encryption.html

[^2_3]: https://docs.confluent.io/confluent-cli/current/cp-produce-consume.html

[^2_4]: https://docs.docker.com/compose/how-tos/use-secrets/

[^2_5]: https://docs.docker.com/reference/compose-file/services/

[^2_6]: https://docs.confluent.io/platform/8.1/security/compliance/secrets/overview.html

[^2_7]: https://docs.confluent.io/platform/current/security/compliance/secrets/overview.html

[^2_8]: https://docs.nvidia.com/ai-workbench/reference/projects/compose-reference/

[^2_9]: https://docs.confluent.io/platform/current/installation/docker/development.html

[^2_10]: https://docs.docker.com/engine/swarm/secrets/

[^2_11]: https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/

[^2_12]: https://docs.confluent.io/platform/7.5/kafka/encryption.html

[^2_13]: https://docs.doppler.com/docs/docker-compose

[^2_14]: https://github.com/docker/docs/blob/main/content/reference/compose-file/secrets.md

[^2_15]: https://docker.ubitools.com/compose/how-tos/use-secrets/

[^2_16]: https://docs.confluent.io/platform/current/installation/docker/config-reference.html


---

# introducing an environment variable with an entrypoint as you suggest doesn't work. When I 2 of them

```yaml
entrypoint:
  - /bin/bash
  - -c
  - |
    set -euo pipefail
    export KAFKA_SSL_KEYSTORE_PASSWORD="$(cat /run/secrets/keystore_password)"
    export KAFKA_SSL_KEY_PASSWORD="$(cat /run/secrets/key_password)"
    export KAFKA_SSL_TRUSTSTORE_PASSWORD="$(cat /run/secrets/truststore_password)"
    exec /etc/confluent/docker/runentrypoint:
  - /bin/bash
  - -c
  - |
    set -euo pipefail
    export KAFKA_SSL_KEY_PASSWORD="$(cat /run/secrets/key_password)"
    export KAFKA_SSL_TRUSTSTORE_PASSWORD="$(cat /run/secrets/truststore_password)"
    exec /etc/confluent/docker/run
```

Keeping the KAFKA_SSL_KEYSTORE_PASSWORD assigned under environment so at least the container will start. Checking with `docker exec -it broker-1 bash`
The files under /run/secrets/ are there, containing the password on a single line
the environment variables KAFKA_SSL_KEY_PASSWORD and KAFKA_SSL_TRUSTSTORE_PASSWORD cannot be found with the `printenv` command or the `echo $KAFKA_SSL_TRUSTSTORE_PASSWORD`

Your wrapper is probably working. The reason `docker exec ... printenv` does not show `KAFKA_SSL_KEY_PASSWORD` or `KAFKA_SSL_TRUSTSTORE_PASSWORD` is that `docker exec` starts a **new** process using the environment configured when the container was created; it is not a child of PID 1 and does not inherit variables that the entrypoint exported at runtime.[^3_1][^3_2]

## Verify PID 1 instead

Check the environment of the actual Kafka startup process:

```bash
docker exec -it broker-1 bash -c \
  'tr "\0" "\n" < /proc/1/environ | grep "^KAFKA_SSL_"'
```

You should see all three variables there if the wrapper ran successfully:

```text
KAFKA_SSL_KEYSTORE_PASSWORD=...
KAFKA_SSL_KEY_PASSWORD=...
KAFKA_SSL_TRUSTSTORE_PASSWORD=...
```

Avoid `echo "$KAFKA_SSL_..."` in an interactive `docker exec` shell for verification: it will be empty even when the broker process has the value.[^3_2][^3_1]

## Fix the Compose YAML

Your pasted YAML appears to contain **two `entrypoint:` keys** and a malformed line:

```yaml
exec /etc/confluent/docker/runentrypoint:
```

Compose will not behave predictably with duplicate keys, and the malformed concatenation suggests the block scalar may have lost a newline. Use exactly one `entrypoint`, with correct indentation:

```yaml
services:
  kafka:
    image: confluentinc/cp-kafka:8.2.0
    entrypoint:
      - /bin/bash
      - -c
      - |
        set -euo pipefail
        export KAFKA_SSL_KEYSTORE_PASSWORD="$(cat /run/secrets/keystore_password)"
        export KAFKA_SSL_KEY_PASSWORD="$(cat /run/secrets/key_password)"
        export KAFKA_SSL_TRUSTSTORE_PASSWORD="$(cat /run/secrets/truststore_password)"
        exec /etc/confluent/docker/run
    environment:
      # Keep only non-secret configuration here.
      KAFKA_SSL_KEYSTORE_LOCATION: /etc/kafka/secrets/kafka.broker.keystore.jks
      KAFKA_SSL_TRUSTSTORE_LOCATION: /etc/kafka/secrets/kafka.broker.truststore.jks
      # ...
    secrets:
      - keystore_password
      - key_password
      - truststore_password

secrets:
  keystore_password:
    file: ./secrets/keystore_password.txt
  key_password:
    file: ./secrets/key_password.txt
  truststore_password:
    file: ./secrets/truststore_password.txt
```

`entrypoint` overrides the image’s Dockerfile entrypoint, while `environment` defines the container’s initially configured environment; runtime `export` commands affect only the entrypoint shell and its `exec`’ed child process.[^3_3][^3_4]

## Debug the startup failure

If the container still exits, first confirm the wrapper itself can read every secret:

```bash
docker compose run --rm --entrypoint /bin/bash kafka -c '
  set -euo pipefail
  for f in /run/secrets/keystore_password \
           /run/secrets/key_password \
           /run/secrets/truststore_password; do
    test -s "$f" || { echo "missing or empty: $f"; exit 1; }
    printf "%s: %s bytes\n" "$f" "$(wc -c < "$f")"
  done
'
```

Then inspect the broker logs:

```bash
docker compose logs --no-log-prefix kafka
```

If `/proc/1/environ` contains the passwords but Kafka still fails, the issue is no longer secret injection—it is the TLS configuration itself: keystore/truststore path, file format, alias, listener protocol, or a mismatch between the key password and keystore password. Confluent maps these environment variables to the standard Kafka properties `ssl.keystore.password`, `ssl.key.password`, and `ssl.truststore.password`.[^3_5][^3_6]

<span style="display:none">[^3_10][^3_11][^3_12][^3_13][^3_14][^3_15][^3_16][^3_17][^3_7][^3_8][^3_9]</span>

<div align="center">⁂</div>

[^3_1]: https://docs.docker.com/reference/cli/docker/container/exec/

[^3_2]: https://stackoverflow.com/questions/66385828/exported-environmental-variable-via-docker-entrypoint-are-not-shown-when-logging

[^3_3]: https://docs.docker.com/reference/compose-file/services.md

[^3_4]: https://docs.docker.com/reference/dockerfile/

[^3_5]: https://docs.confluent.io/platform/8.1/installation/docker/development.html

[^3_6]: https://docs.confluent.io/platform/7.6/kafka/encryption.html

[^3_7]: https://docs.docker.com/reference/cli/docker/compose/

[^3_8]: https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables.md

[^3_9]: https://docs.docker.com/reference/cli/docker/compose/exec/

[^3_10]: https://docs.docker.com/compose/how-tos/environment-variables/envvars/

[^3_11]: https://docs.docker.com/compose/how-tos/environment-variables/envvars-precedence/

[^3_12]: https://docs.docker.jp/v20.10/compose/environment-variables.html

[^3_13]: https://github.com/luci-digital/luci-KiroCrew/blob/main/docs/guides/docker-troubleshooting.md

[^3_14]: https://docs.docker.jp/v17.06/compose/environment-variables.html

[^3_15]: https://docs.docker.jp/v19.03/compose/environment-variables.html

[^3_16]: https://jhooq.com/docker-manage-environment-variable/

[^3_17]: https://github.com/docker/compose/issues/5600


---

# The last version of the docker compose file with the entrypoint works the broker container starts up and encrypted events can be produced and consumed and the

```bash
docker exec -it broker-1 bash -c \
  'tr "\0" "\n" < /proc/1/environ | grep "^KAFKA_SSL_"'
```

shows all 3 the passwords from the secrets files are set to their respective environment variables.
Thank you for clearing that up.

Great—that confirms the full chain is working correctly:

- Compose grants the Kafka service access to the three file-based secrets.
- The entrypoint wrapper reads each file from `/run/secrets/` and exports it as the corresponding `KAFKA_SSL_*` variable.
- PID 1—the Confluent Kafka startup process—receives those variables and converts them into the broker’s TLS properties.
- Successful encrypted produce/consume proves the keystore, key, and truststore passwords are all correct.

The earlier `docker exec` confusion was just a Docker process-model detail: an exec shell gets the container’s creation-time environment, not variables exported later by PID 1. Checking `/proc/1/environ` is the right verification method.[^4_1][^4_2]

One optional hardening step: ensure the secret files have restrictive host permissions, for example:

```bash
chmod 600 secrets/*.txt
```

And keep `.gitignore` covering the `secrets/` directory so the plaintext password files cannot be committed accidentally.

<div align="center">⁂</div>

[^4_1]: https://docs.docker.com/reference/cli/docker/container/exec/

[^4_2]: https://stackoverflow.com/questions/66385828/exported-environmental-variable-via-docker-entrypoint-are-not-shown-when-logging


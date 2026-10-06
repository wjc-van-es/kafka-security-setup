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

# Resources

## Apache Kafka broker property references
- In Confluent docker images like `confluentinc/cp-kafka:8.2.0` we can configure all Apache Kafka broker properties as
  environment variables. 
- The translation from property name to environment variable name is as follows:
  - the lower case becomes uppercase 
  - all dot separators become underscores (`. -> _`)
  - the environment variable is prefixed with `KAFKA_`
  - e.g. 
    - from property to env var: `controller.listener.names` -> `KAFKA_CONTROLLER_LISTENER_NAMES`
    - or from env var to property picking one in [../docker-compose-tls.yml](../docker-compose-tls.yml)
      - `KAFKA_ADVERTISED_LISTENERS` -> `advertised.listeners`
      - `KAFKA_SSL_KEYSTORE_CREDENTIALS` -> `ssl.keystore.credentials`
- The Kafka properties can be looked up online
  - For the current version at:
    [https://docs.confluent.io/platform/current/installation/configuration/broker-configs.html](https://docs.confluent.io/platform/current/installation/configuration/broker-configs.html)
  - For the Confluent version 8.2:
    [https://docs.confluent.io/platform/8.2/installation/configuration/broker-configs.html#search-by-configuration-property-name](https://docs.confluent.io/platform/8.2/installation/configuration/broker-configs.html#search-by-configuration-property-name)

## Q&A
- signing a csr with `SAN` entries using `openssl`

  [https://www.perplexity.ai/search/cec90d8c-0804-43b6-b49e-b8a0c5f77366](https://www.perplexity.ai/search/cec90d8c-0804-43b6-b49e-b8a0c5f77366)
- kafka CLI to show number of events on a specified topic
  
  [https://www.perplexity.ai/search/ea58049b-639e-4061-aa09-3b391299e39d](https://www.perplexity.ai/search/ea58049b-639e-4061-aa09-3b391299e39d)
package nl.vea.kafka.security.encryption;

import org.apache.kafka.clients.CommonClientConfigs;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.config.SslConfigs;
import org.apache.kafka.common.serialization.StringSerializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Instant;
import java.util.Objects;
import java.util.Properties;
import java.util.UUID;
import java.util.stream.IntStream;

import static nl.vea.kafka.security.ApplicationConfig.BROKER_HOST;
import static nl.vea.kafka.security.ApplicationConfig.TOPIC;

public class BasicSSLProducer {

    // for this to work the environment variables must be set; we used a .env file that won't be shared in the Git repo
    private static final String CLIENT_SECRET = System.getenv("CLIENT_SECRET");
    private static final String DEBUG_SSL_HANDSHAKE = System.getenv("DEBUG_SSL_HANDSHAKE");
    private static final String TRUSTSTORE_LOCATION = System.getenv("TRUSTSTORE_LOCATION");
    private static final Logger log = LoggerFactory.getLogger(BasicSSLProducer.class);

    static {
        if (Objects.nonNull(DEBUG_SSL_HANDSHAKE) && Boolean.parseBoolean(DEBUG_SSL_HANDSHAKE)) {
            System.setProperty("javax.net.debug", "ssl:handshake");
        }
    }

    static void main() {
        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, BROKER_HOST);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, "SSL");

        // We need to have an absolute path for this property
        props.put(SslConfigs.SSL_TRUSTSTORE_LOCATION_CONFIG, TRUSTSTORE_LOCATION); // Replace with the absolute path on your machine
        props.put(SslConfigs.SSL_TRUSTSTORE_PASSWORD_CONFIG, CLIENT_SECRET);

        try (KafkaProducer<String, String> producer = new KafkaProducer<>(props)) {
            Thread haltedHook = new Thread(producer::close);
            Runtime.getRuntime().addShutdownHook(haltedHook);

            IntStream.range(0, 20).forEach(i -> {
                String key = String.valueOf(i);
                String value = UUID.randomUUID() + "_-_" + Instant.now().toString();
                ProducerRecord<String, String> producerRecord =
                        new ProducerRecord<>(TOPIC, key, value);
                producer.send(producerRecord);
                log.info("Message sent: {}:{}", key, value);
            });
        }
    }
}

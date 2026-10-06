package nl.vea.kafka.security.encryption;

import org.apache.kafka.clients.CommonClientConfigs;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.config.SslConfigs;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.util.Collections;
import java.util.Objects;
import java.util.Properties;

import static nl.vea.kafka.security.ApplicationConfig.*;

public class BasicSSLConsumer {

    // for this to work the environment variables must be set; we used a .env file that won't be shared in the Git repo
    private static final String CLIENT_SECRET = System.getenv("CLIENT_SECRET");
    private static final String DEBUG_SSL_HANDSHAKE = System.getenv("DEBUG_SSL_HANDSHAKE");
    private static final String TRUSTSTORE_LOCATION = System.getenv("TRUSTSTORE_LOCATION");
    private static final Logger log = LoggerFactory.getLogger(BasicSSLConsumer.class);

    static {
        if (Objects.nonNull(DEBUG_SSL_HANDSHAKE) && Boolean.parseBoolean(DEBUG_SSL_HANDSHAKE)) {
            System.setProperty("javax.net.debug", "ssl:handshake");
        }
    }

    static void main() {
        Properties props = new Properties();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, BROKER_HOST);
        props.put(ConsumerConfig.GROUP_ID_CONFIG, CONSUMER_GROUP);

        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());

        props.put(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, "SSL");

        // We need to have an absolute path for this property
        props.put(SslConfigs.SSL_TRUSTSTORE_LOCATION_CONFIG, TRUSTSTORE_LOCATION); // Replace with the absolute path on your machine
        props.put(SslConfigs.SSL_TRUSTSTORE_PASSWORD_CONFIG, CLIENT_SECRET);

        try (KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props)) {

            Thread haltedHook = new Thread(consumer::close);
            Runtime.getRuntime().addShutdownHook(haltedHook);

            consumer.subscribe(Collections.singletonList(TOPIC));

            while (true) {
                ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));

                records.forEach(consumerRecord -> log.info(
                        "Consumed message: {}:{}", consumerRecord.key(), consumerRecord.value()));
            }
        }
    }
}

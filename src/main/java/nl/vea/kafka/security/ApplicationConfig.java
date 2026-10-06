package nl.vea.kafka.security;

public class ApplicationConfig {
    private ApplicationConfig() {
    }

    public static final String BROKER_HOST = "localhost:9092";
    public static final String CONSUMER_GROUP = "basic.consumer";
    public static final String TOPIC = "basic-topic";
}

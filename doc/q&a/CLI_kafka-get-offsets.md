<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# kafka CLI to show number of events on a specified topic

Use `kafka-get-offsets.sh` to retrieve the latest offset for every partition, then sum the offsets:

```bash
bin/kafka-get-offsets.sh \
  --bootstrap-server localhost:9092 \
  --topic my-topic \
| awk -F: '{ sum += $3 } END { print sum }'
```

For older Kafka distributions, use `GetOffsetShell`:

```bash
bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic my-topic \
  --time -1 \
| awk -F: '{ sum += $3 } END { print sum }'
```

The output is the approximate number of records currently retained in the topic, calculated as:

$$
\text{records} = \sum_{\text{partitions}}(\text{latest offset} - \text{earliest offset})
$$

To account for retention and non-zero starting offsets, use both earliest and latest offsets:

```bash
latest=$(
  bin/kafka-get-offsets.sh \
    --bootstrap-server localhost:9092 \
    --topic my-topic \
    --time -1
)

earliest=$(
  bin/kafka-get-offsets.sh \
    --bootstrap-server localhost:9092 \
    --topic my-topic \
    --time -2
)

paste \
  <(echo "$latest" | sort -t: -k2,2n) \
  <(echo "$earliest" | sort -t: -k2,2n) |
awk -F'\t' '
{
  split($1, l, ":")
  split($2, e, ":")
  total += l[^1_3] - e[^1_3]
}
END { print total }
'
```

For a topic with partitions whose earliest/latest offsets are `0/100`, `0/250`, and `10/90`, the retained record count is $100 + 250 + (90 - 10) = 430$. Kafka offsets are partition-local and may contain gaps, so this is an offset-range estimate rather than a recount of every physical record.[^1_1][^1_2]

<span style="display:none">[^1_10][^1_4][^1_5][^1_6][^1_7][^1_8][^1_9]</span>

<div align="center">⁂</div>

[^1_1]: https://kafka.apache.org/41/operations/basic-kafka-operations/

[^1_2]: https://stackoverflow.com/questions/78012679/how-to-inspect-the-number-of-events-on-a-kafka-topic-using-the-cli

[^1_3]: https://docs.confluent.io/kafka/operations-tools/kafka-tools.html

[^1_4]: https://hevodata.com/learn/kafka-cli-commands/

[^1_5]: https://docs.cloudera.com/documentation/enterprise/6/6.1/topics/kafka_admin_cli.html

[^1_6]: https://www.redpanda.com/guides/kafka-architecture-kafka-tools

[^1_7]: https://github.com/3axap4eHko/kafka-console

[^1_8]: https://gist.github.com/sonhmai/5b2b4455162c808c091b661aeb675625

[^1_9]: https://github.com/SepehrImanian/kafka-docs/blob/main/kafka-cli.md

[^1_10]: https://dev.to/jeden/notes-on-kafka-kafka-cli-2jeo


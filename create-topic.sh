#!/usr/bin/env bash

###############################################################################################
# This idempotent script creates the necessary topic when absent.
# It can be run after the command
# docker compose up -d
###############################################################################################
declare TOPIC="user-tracking-avro"
# declare -i TOPIC_ABSENT=1 # 1 meaning truly absent and 0 meaning actually present
declare TOPIC_ABSENT=true
declare -a TOPICS
declare -i INDEX=0

# take the name of the topic from the first argument if present
if [ -n "$1" ]
then
  TOPIC=$1
fi

echo "Trying to create the topic $TOPIC if not yet present."

# Checking the presence of TOPIC
for line in $(docker exec broker-1 kafka-topics --bootstrap-server broker-1:29092 --list); do
   # echo $line
   # [[ "$line" == *"$KIA_TEST_TOPIC"* ]] && echo "Line contains the KIA_TEST_TOPIC"
    if [[ "$line" == "$TOPIC" ]]; then
        TOPIC_ABSENT=false;
    fi
    TOPICS[${INDEX}]=$line;
    (( INDEX++ )) || true;
done

echo "List of all topics already present: ${TOPICS[*]}"
if $TOPIC_ABSENT
then
  echo "The topic ${TOPIC} is still absent."
else
  echo "The topic ${TOPIC} has already been created."
fi
# echo "TOPIC_ABSENT: $TOPIC_ABSENT"

# Creating TOPIC if absent
if [ $TOPIC_ABSENT == true ]; then
    docker exec broker-1 kafka-topics --bootstrap-server broker-1:29092 --create --topic $TOPIC
fi

echo "current list of topics:"
docker exec broker-1 kafka-topics --bootstrap-server broker-1:29092 --list
echo "Description of the $TOPIC topic:"
docker exec broker-1 kafka-topics --bootstrap-server broker-1:29092 --describe --topic $TOPIC
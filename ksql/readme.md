# kSQL Infrastructure

This directory contains the infrastructure code for deploying kSQL for the Finance Stock project.

## Architecture

*   **Deployment Method**: [Ansible Playbook](https://www.ansible.com/) used for configuration and provisioning.
*   **Host Environment**: Deploying to a virtual machine in the **Cockpit VM Server**.

## Usage & Configuration

KSQL / Kafka connect will be deployed into K8s cluster

```yml
ksqldb-server:
    image: confluentinc/ksqldb-server:latest
    container_name: ksqldb-server
    depends_on:
      - kafka
    ports:
      - "8088:8088"
    environment:
      KSQL_LISTENERS: "http://0.0.0.0:8088"
      # This points directly to the Kafka container name
      KSQL_BOOTSTRAP_SERVERS: "kafka:9092"
      KSQL_KSQL_LOGGING_PROCESSING_STREAM_AUTO_CREATE: "true"
      KSQL_KSQL_LOGGING_PROCESSING_TOPIC_AUTO_CREATE: "true"

  ksqldb-cli:
    image: confluentinc/ksqldb-cli:latest
    container_name: ksqldb-cli
    depends_on:
      - ksqldb-server
    entrypoint: /bin/sh
    tty: true
```

# ai-defra-search-perf-tests

Performance tests for the AI Defra Search application using JMeter.

## Table of Contents

- [Local Architecture](#local-architecture)
- [Running Tests Locally with JMeter](#running-tests-locally-with-jmeter)
- [Running Tests with run-tests-local.sh](#running-tests-with-run-tests-localsh)
- [Licence](#licence)


## Local Architecture

The `compose.yml` file starts the following services:

### Infrastructure Services

| Service | Purpose | Port |
|---------|---------|------|
| **localstack** | AWS service mocking (S3, SQS, SNS) | 4566 |
| **mongodb** | Document database | 27017 |
| **redis** | Cache storage | 6379 |
| **postgres** | Vector database (pgvector) | 5432 |
| **bedrock-mock** | AWS Bedrock stub | 8089 |

### Application Services

| Service | Purpose | Port | Dependencies |
|---------|---------|------|--------------|
| **ai-defra-search-data** | Vector search API | 8085 | localstack, mongodb, postgres |
| **ai-defra-search-agent** | RAG agent backend | 8086 | mongodb, bedrock-mock, ai-defra-search-data |
| **ai-defra-search-frontend** | Web UI (under test) | 3000 | ai-defra-search-agent, redis |
| **development** | JMeter test runner | - | ai-defra-search-frontend |


## Running Tests Locally with JMeter

Run JMeter directly on your machine (requires local JMeter installation).

### Prerequisites

- JMeter installed
- Services running: `ddocker compose up --wait -d`

### Basic Command

```bash
jmeter -n -t scenarios/ai-assistant.jmx \
  -l reports/test-results.csv \
  -e -o reports \
  -Jenv=local \
  -Jprotocol=http \
  -Jdomain=localhost \
  -Jport=3000
```

### Available Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-Jenv` | Environment name | `local` |
| `-Jprotocol` | HTTP scheme | `http` |
| `-Jdomain` | Target hostname | `localhost` |
| `-Jport` | Target port | `3000` |
| `-Jthreads` | Concurrent users | `20` |
| `-JrampTime` | Ramp-up time (seconds) | `10` |
| `-Jduration` | Test duration (seconds) | `60` |
| `-JhttpTimeout` | HTTP timeout (ms) | `30000` |
| `-JmaxResponseTime` | Max response time (ms) | `20000` |
| `-JwaitAfterPageLoad` | Wait after page load (ms) | `5000` |
| `-JwaitAfterQuestion` | Wait after question (ms) | `10000` |

### Override Parameters

```bash
jmeter -n -t scenarios/ai-assistant.jmx \
  -l reports/test-results.csv \
  -e -o reports \
  -Jenv=local \
  -Jprotocol=http \
  -Jdomain=localhost \
  -Jport=3000 \
  -Jthreads=100 \
  -JrampTime=60 \
  -Jduration=600
```

## Running Tests with run-tests-local.sh

Automated script that starts Docker services and runs JMeter locally.

### What It Does

1. Removes existing containers
2. Rebuilds `development` service
3. Starts all services
4. Removes old reports
5. Runs JMeter locally

### Execute

```bash
./run-tests-local.sh
```

### Override Parameters

**Option 1: Edit the script**

Change parameter values in the jmeter command in the run-tests-local.sh script.



## Licence

THIS INFORMATION IS LICENSED UNDER THE CONDITIONS OF THE OPEN GOVERNMENT LICENCE found at:

<http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3>

The following attribution statement MUST be cited in your products and applications when using this information.

> Contains public sector information licensed under the Open Government licence v3

### About the licence

The Open Government Licence (OGL) was developed by the Controller of Her Majesty's Stationery Office (HMSO) to enable
information providers in the public sector to license the use and re-use of their information under a common open
licence.

It is designed to encourage use and re-use of information freely and flexibly, with only a few conditions.

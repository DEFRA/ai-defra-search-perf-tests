# ai-defra-search-perf-tests

Performance tests for the AI Defra Search application using JMeter.

## Table of Contents

- [Local Architecture](#local-architecture)
- [Running Tests Locally with JMeter](#running-tests-locally-with-jmeter)
- [Running Tests with run-tests-local.sh](#running-tests-with-run-tests-localsh)
- [Running Tests with run-tests-local-docker.sh](#running-tests-with-run-tests-local-dockersh)
- [Seeding the local knowledge base with synthetic data](#seeding-the-local-knowledge-base-with-synthetic-data)
- [Seeding the perf-test environment knowledge base with synthetic data](#seeding-the-perf-test-environment-knowledge-base-with-synthetic-data)
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
| **ai-defra-search-knowledge** | Knowledge/RAG API | 8085 | localstack, mongodb, postgres |
| **ai-defra-search-agent** | RAG agent backend | 8086 | mongodb, bedrock-mock, ai-defra-search-knowledge |
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
| `-JagentDomain` | Hostname for agent `GET /conversations/{id}` (RAG assertion) | `localhost` |
| `-JagentPort` | Port for agent API | `8086` |
| `-JknowledgeGroupId` | Mongo id of the knowledge group used in chat requests | (see `ai-assistant.jmx`) |

After each frontend poll step, the scenario calls the agent conversation API and fails if the latest assistant message has `ragError` set (RAG retrieval failed). Use the same host you use to reach the agent from the JMeter process (`localhost` when JMeter runs on the host with compose ports published; `ai-defra-search-agent` when JMeter runs inside the perf `development` container — the compose `entrypoint.sh` passes this via `AGENT_SERVICE_ENDPOINT`).

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

1. Removes all existing containers
2. Tears down volumes and networks
3. Builds the `development` image fresh (with `--no-cache`)
4. Starts all services and waits for them to be healthy
5. Removes old reports
6. Runs JMeter locally against `localhost:3000`

### Execute

```bash
./run-tests-local.sh
```

### Override Parameters

**Option 1: Edit the script**

Change parameter values in the jmeter command in the run-tests-local.sh script.


## Running Tests with run-tests-local-docker.sh

Automated script that runs the full test suite entirely within Docker — no local JMeter installation required.

### What It Does

1. Removes all existing containers
2. Tears down volumes and networks
3. Removes old reports
4. Builds the `development` image fresh (with `--no-cache`)
5. Starts all supporting services and waits for them to be healthy
6. Runs JMeter inside the `development` container
7. Removes the container on completion

### Execute

```bash
./run-tests-local-docker.sh
```

### Override Parameters

**Option 1: Edit `compose.yml`**

Change the environment variable values under the `development` service in `compose.yml`.

| Variable | Description | Default |
|----------|-------------|---------|
| `THREADS` | Concurrent users | `5` |
| `RAMP_TIME` | Ramp-up time (seconds) | `10` |
| `DURATION` | Test duration (seconds) | `120` |
| `HTTP_TIMEOUT` | HTTP timeout (ms) | `60000` |
| `MAX_RESPONSE_TIME` | Max response time (ms) | `30000` |
| `WAIT_AFTER_PAGE_LOAD` | Wait after page load (ms) | `3000` |
| `WAIT_AFTER_QUESTION` | Wait after question (ms) | `5000` |


## Seeding the local knowledge base with synthetic data

When running the performance tests locally, both the MongoDB and PostgreSQL databases are automatically seeded with synthetic test data as part of the Docker Compose startup process.

### MongoDB (ai-defra-search-knowledge)

The MongoDB database is seeded via the `compose/scripts/mongodb/init-mongodb.sh` script, which is mounted into the MongoDB container and executed automatically on first start via the Docker `docker-entrypoint-initdb.d` mechanism.

It uses `mongoimport` to upsert the following collections into the `ai-defra-search-knowledge` database:

| File | Collection |
|------|------------|
| `compose/scripts/mongodb/data/knowledgeGroups.json` | `knowledgeGroups` |
| `compose/scripts/mongodb/data/documents.json` | `documents` |

### PostgreSQL (ai-defra-search-knowledge)

The PostgreSQL database is seeded via SQL scripts that are mounted into the Postgres container and executed automatically on first start, also via `docker-entrypoint-initdb.d`. The scripts run in order:

| File | Purpose |
|------|---------|
| `compose/scripts/postgres/00-truncate-tables.sql` | Clears existing data |
| `compose/scripts/postgres/01-create-tables.sql` | Creates the `knowledge_vectors` table with the `pgvector` extension |
| `compose/scripts/postgres/02-seed-postgres.sql` | Inserts synthetic knowledge vector records with `metadata->>'knowledge_group_id' = '674f1f77bcf86cd799439011'` |

### Updating the local seed data

To update the synthetic data used for local runs, edit the files listed above and restart the stack, ensuring volumes are cleared so the init scripts are re-run:

```bash
docker compose down -v && docker compose up --wait -d
```


## Seeding the perf-test environment knowledge base with synthetic data

The perf-test **runner** can seed MongoDB and PostgreSQL **before JMeter** when both are true:

1. **`CREATE_KNOWLEDGE_BASE`** is enabled (`true`, `1`, or `yes`, case-insensitive — not only the exact string `true`).
2. The job supplies connection settings the runner can use from the CDP network:
   - **`MONGO_URI`**: full connection string for DocumentDB (TLS, user, password, `tlsCAFile` / `authSource` in the URI as required). The seed script uses `mongoimport --uri=...` so it is **not** limited to host + port.
   - **`POSTGRES_HOST`**, **`POSTGRES_PORT`**, **`POSTGRES_DB`**, **`POSTGRES_USER`**, **`POSTGRES_PASSWORD`**, and usually **`POSTGRES_SSL_MODE=require`** (or whatever your RDS/DocumentDB proxy needs).

`entrypoint.sh` runs `scripts/setup-databases.sh` when seeding is enabled; otherwise it logs that seeding was skipped (check CDP logs if fixtures are missing).

Set **`ENVIRONMENT=perf-test`** so Postgres seeding truncates `knowledge_vectors` before re-inserting (case-insensitive). Mongo uses **upserts** on `_id` for `knowledgeGroups` and `documents` (see `compose/scripts/mongodb/data/`).

If the perf job **cannot** reach the databases (network policy), you must seed by another path (e.g. one-off task, migration, or pipeline with DB access) using the same fixture IDs as locally (`674f1f77bcf86cd799439011` for the default JMeter `knowledgeGroupId`).


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

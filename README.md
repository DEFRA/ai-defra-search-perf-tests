# ai-defra-search-perf-tests

A JMeter based test runner for the CDP Platform.

- [Licence](#licence)
  - [About the licence](#about-the-licence)

## Build

Test suites are built automatically by the [.github/workflows/publish.yml](.github/workflows/publish.yml) action whenever a change are committed to the `main` branch.
A successful build results in a Docker container that is capable of running your tests on the CDP Platform and publishing the results to the CDP Portal.

## Run

The performance test suites are designed to be run from the CDP Portal.
The CDP Platform runs test suites in much the same way it runs any other service, it takes a docker image and runs it as an ECS task, automatically provisioning infrastructure as required.

## Local Testing with Docker Compose

You can run the entire performance test stack locally using Docker Compose, including LocalStack, Redis, and the target service. This is useful for development, integration testing, or verifying your test scripts **before committing to `main`**, which will trigger GitHub Actions to build and publish the Docker image.

### Build the Docker image

```bash
docker compose build --no-cache development
```

This ensures any changes to `entrypoint.sh` or other scripts are picked up properly.

---

### Start the full test stack

```bash
docker compose up --build
```

This brings up:

* `development`: the container that runs your performance tests
* `localstack`: simulates AWS S3, SNS, SQS, etc.
* `redis`: backing service for cache
* `service`: the application under test

Once all services are healthy, your performance tests will automatically start.

---

### Replace `service-name` in Compose File

In the `docker-compose.yml`, make sure to replace:

```yaml
image: defradigital/service-name:${SERVICE_VERSION:-latest}
```

with the actual name of your service’s image.

This is the service under test, which must expose a `/health` endpoint and listen on port `3000`.

---

### Notes

* S3 bucket is expected to be `s3://test-results`, automatically created inside LocalStack.
* Logs and reports are written to `./reports` on your host.
* `entrypoint.sh` should contain the logic to wait for dependencies and kick off the test run.
* The `depends_on` healthchecks ensure services like `localstack` and `service` are ready before tests start.
* If you make changes to test scripts or entrypoints, rerun with:

```bash
docker compose up --build
```

## Local Testing with LocalStack

### Build a new Docker image
```
docker build . -t my-performance-tests
```
### Create a Localstack bucket
```
aws --endpoint-url=localhost:4566 s3 mb s3://my-bucket
```

### Run performance tests

```
docker run \
-e S3_ENDPOINT='http://host.docker.internal:4566' \
-e RESULTS_OUTPUT_S3_PATH='s3://my-bucket' \
-e AWS_ACCESS_KEY_ID='test' \
-e AWS_SECRET_ACCESS_KEY='test' \
-e AWS_SECRET_KEY='test' \
-e AWS_REGION='eu-west-2' \
my-performance-tests
```

docker run -e S3_ENDPOINT='http://host.docker.internal:4566' -e RESULTS_OUTPUT_S3_PATH='s3://cdp-infra-dev-test-results/cdp-portal-perf-tests/95a01432-8f47-40d2-8233-76514da2236a' -e AWS_ACCESS_KEY_ID='test' -e AWS_SECRET_ACCESS_KEY='test' -e AWS_SECRET_KEY='test' -e AWS_REGION='eu-west-2' -e ENVIRONMENT='perf-test' my-performance-tests

---

## RAG Stack Testing

### Quick Start

To test the complete RAG (Retrieval-Augmented Generation) stack with all initialization:

```bash
# Stop and remove all containers and volumes (ensures fresh initialization)
docker compose down -v

# Start all services
docker compose up -d

# Wait for all services to be healthy (~30 seconds)
sleep 30

# Check service status
docker compose ps
```

**What gets automatically initialized:**
- ✅ PostgreSQL with pgvector extension
- ✅ Liquibase migrations creating `knowledge_vectors` table
- ✅ Database seeded with 5 UCD knowledge vectors (`snapshot_id='kg_34vf0wr3e06l'`)
- ✅ MongoDB with knowledge group and snapshot metadata
- ✅ Bedrock mocks for embeddings (Titan) and chat (Claude)
- ✅ All services connected and configured

### Verify Setup

```bash
# Check PostgreSQL data
docker compose exec postgres psql -U postgres -d ai_defra_search_data \
  -c "SELECT COUNT(*), snapshot_id FROM knowledge_vectors GROUP BY snapshot_id;"
# Expected output: 5 | kg_34vf0wr3e06l

# Check MongoDB data
docker compose exec mongodb mongosh ai-defra-search-data --quiet --eval \
  "db.knowledgeGroups.countDocuments({groupId: 'kg_34vf0wr3e06l'})"
# Expected output: 1

# Check seeder logs
docker compose logs seeder | grep "Seed data"
```

### Test the RAG Stack

```bash
# Test data service (vector similarity search)
curl -X POST http://localhost:8085/snapshots/query \
  -H "Content-Type: application/json" \
  -d '{"groupId": "kg_34vf0wr3e06l", "query": "What is UCD?"}'

# Expected: Returns similar documents from knowledge base

# Test agent (full RAG chat flow)
curl -X POST http://localhost:8086/chat \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is UCD?",
    "modelId": "anthropic.claude-3-haiku-20240307-v1:0"
  }'

# Expected: Returns AI-generated response using knowledge base context

# Access frontend
open http://localhost:3000
```

### Architecture

```
User Query
    ↓
Frontend (3000) → Agent (8086) → Data Service (8085)
                      ↓                   ↓
                  Bedrock Mock       PostgreSQL (pgvector)
                  (8089)             MongoDB (metadata)
                      ↓
                  - Embeddings (Titan)
                  - Chat (Claude)
```

### Service Endpoints

- **Frontend**: http://localhost:3000
- **Agent**: http://localhost:8086
  - `/health` - Health check
  - `/chat` - Chat endpoint
- **Data Service**: http://localhost:8085
  - `/health` - Health check
  - `/snapshots/query` - Knowledge base query
- **Bedrock Mock**: http://localhost:8089
  - Embedding model: `amazon.titan-embed-text-v2:0`
  - Chat models: Claude 3.7 Sonnet, Claude 3 Haiku
- **PostgreSQL**: localhost:5432
  - Database: `ai_defra_search_data`
  - User: `postgres` / Password: `ppp`
- **LocalStack**: http://localhost:4566

### Troubleshooting

**If services fail to start:**
```bash
# Check logs
docker compose logs --tail 50 ai-defra-search-data
docker compose logs --tail 50 ai-defra-search-agent

# Restart specific service
docker compose restart ai-defra-search-data
```

**If RAG queries return 400/500 errors:**
```bash
# Verify MongoDB has correct data
docker compose exec mongodb mongosh ai-defra-search-data --quiet --eval \
  "db.knowledgeGroups.find({groupId: 'kg_34vf0wr3e06l'}).pretty()"

# Should show: title, owner, activeSnapshot fields

# Verify PostgreSQL has vectors
docker compose exec postgres psql -U postgres -d ai_defra_search_data \
  -c "SELECT COUNT(*) FROM knowledge_vectors WHERE snapshot_id = 'kg_34vf0wr3e06l';"

# Should return: 5
```

**MongoDB data not persisting?**
- This is intentional for testing
- MongoDB doesn't use a persistent volume, so init scripts run on every fresh start
- Use `docker compose down -v` to fully reset

---

## Debugging JMeter Test Failures

When JMeter tests fail with assertion errors (e.g., "text expected to match /.+/"), you need to see what was actually received. The test suite now includes several debugging mechanisms:

### 1. View Response Data in Reports

After running tests, check the `./reports` directory for generated files:

```bash
# List generated report files
ls -la ./reports/

# View CSV report with full response data
cat ./reports/*-ai-assistant-report.csv | less

# View debug JTL file (XML format with full request/response details)
cat ./reports/*-ai-assistant-debug.jtl | less
```

The CSV and JTL files now include:
- ✅ Full response body (`responseData`)
- ✅ Response headers (`responseHeaders`)
- ✅ Request headers (`requestHeaders`)
- ✅ Response code and message
- ✅ Assertion failure messages

### 2. View JMeter Console Logs

The JSR223 PostProcessor logs detailed response information to the JMeter console:

```bash
# View logs from the performance test container
docker compose logs development | grep "Response"

# Look for lines like:
# Response Code: 200
# Response Message: OK
# Response Headers: Content-Type: text/html...
# Response Data: <html>...</html>
# Response Size: 1234 bytes
```

### 3. Check JMeter Log File

JMeter creates a detailed log file during execution:

```bash
# View the JMeter log file (if mounted or accessible)
docker compose exec development cat /opt/perftest/logs/perftest-ai-assistant.log

# Or copy it from container after run
docker cp $(docker compose ps -q development):/opt/perftest/logs/perftest-ai-assistant.log ./reports/
```

### 4. Run with Debug Output

For immediate debugging, run tests with increased logging:

```bash
# Set log level to DEBUG for HTTP protocol
docker compose up development 2>&1 | tee test-output.log

# Then search for response details
grep -A 10 "Response Code" test-output.log
```

### Common Debugging Scenarios

**Empty Response Body:**
- Check if the endpoint returns HTML redirect instead of JSON
- Verify the API endpoint path is correct (e.g., `/api/chat` vs `/start`)
- Ensure Content-Type headers match expected format

**Timeout Issues:**
- Increase `HTTPSampler.response_timeout` in JMX file
- Check service health: `docker compose ps`
- Verify backend dependencies are responding

**Authentication Failures:**
- Check if endpoint requires auth (cookies, tokens)
- Verify CookieManager is capturing session cookies
- Look for 401/403 response codes in logs

**Assertion Failures:**
- Review the actual response data in CSV/JTL files
- Check if response format changed (JSON vs HTML)
- Verify regex patterns match actual content

### Enable/Disable Debug Listeners

To reduce overhead in production tests, you can disable debug listeners in the JMX file:
- Summary Report: Always enabled (lightweight)
- View Results Tree: Disable by setting `enabled="false"` (generates large files)
- JSR223 PostProcessor: Disable if console logging not needed



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

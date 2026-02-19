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

### Parameterizing Tests in Docker

You can override test parameters using environment variables when running with Docker Compose:

```bash
# Run with custom test parameters
THREADS=50 RAMP_TIME=30 DURATION=300 docker compose up

# Or use an environment file
docker compose --env-file my-test-config.env up
```

**Available Environment Variables:**

| Variable | Description | Default | Unit |
|----------|-------------|---------|------|
| `THREADS` | Number of concurrent users | 20 | users |
| `RAMP_TIME` | Time to ramp up all users | 10 | seconds |
| `DURATION` | Total test duration | 60 | seconds |
| `HTTP_TIMEOUT` | HTTP request timeout | 30000 | milliseconds |
| `MAX_RESPONSE_TIME` | Maximum acceptable response time | 20000 | milliseconds |
| `WAIT_AFTER_PAGE_LOAD` | Pause after loading the chat page | 5000 | milliseconds |
| `WAIT_AFTER_QUESTION` | Pause after submitting each question | 10000 | milliseconds |

**Example: Create a test configuration file `performance-test.env`:**

```bash
THREADS=100
RAMP_TIME=60
DURATION=600
HTTP_TIMEOUT=60000
MAX_RESPONSE_TIME=30000
WAIT_AFTER_PAGE_LOAD=3000
WAIT_AFTER_QUESTION=5000
```

Then run:

```bash
docker compose --env-file performance-test.env up
```

### Pre-configured Test Scenario

The repository includes a ready-to-use performance test configuration file:

- **`test-configs/performance-test.env`**: High load scenario (100 users, 10 minutes)

Use it with Docker Compose:

```bash
docker compose --env-file test-configs/performance-test.env up
```

Or with JMeter directly:

```bash
# Load environment variables and run JMeter
export $(cat test-configs/performance-test.env | xargs)
jmeter -n -t scenarios/ai-assistant.jmx -l reports/performance-test.csv -e -o reports \
  -Jthreads=$THREADS -JrampTime=$RAMP_TIME -Jduration=$DURATION \
  -JhttpTimeout=$HTTP_TIMEOUT -JmaxResponseTime=$MAX_RESPONSE_TIME \
  -JwaitAfterPageLoad=$WAIT_AFTER_PAGE_LOAD -JwaitAfterQuestion=$WAIT_AFTER_QUESTION
```

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

## Running JMeter Tests Locally

### Run a test scenario with HTML report generation

To run JMeter tests locally (outside Docker) and generate HTML reports:

```bash
# Run test with live HTML dashboard generation (default parameters)
jmeter -n -t scenarios/ai-assistant.jmx \
  -l reports/test-results.csv \
  -e -o reports \
  -Jenv=local \
  -JHTTP_PROTOCOL=http \
  -JAI_DEFRA_SEARCH_FRONTEND_HOST=ai-defra-search-frontend \
  -JAI_DEFRA_SEARCH_FRONTEND_PORT=3000
```

### Parameterizing Test Execution

You can customize test parameters via `-J` command-line properties:

```bash
# Run test with custom parameters
jmeter -n -t scenarios/ai-assistant.jmx \
  -l reports/test-results.csv \
  -e -o reports \
  -Jenv=local \
  -JHTTP_PROTOCOL=http \
  -JAI_DEFRA_SEARCH_FRONTEND_HOST=ai-defra-search-frontend \
  -JAI_DEFRA_SEARCH_FRONTEND_PORT=3000 \
  -Jthreads=20 \
  -JrampTime=30 \
  -Jduration=300 \
  -JhttpTimeout=60000 \
  -JmaxResponseTime=30000 \
  -JwaitAfterPageLoad=3000 \
  -JwaitAfterQuestion=5000
```

**Available Test Parameters:**

| Parameter | Description | Default | Unit |
|-----------|-------------|---------|------|
| `threads` | Number of concurrent users | 20 | users |
| `rampTime` | Time to ramp up all users | 10 | seconds |
| `duration` | Total test duration | 60 | seconds |
| `httpTimeout` | HTTP request timeout | 30000 | milliseconds |
| `maxResponseTime` | Maximum acceptable response time (assertion) | 20000 | milliseconds |
| `waitAfterPageLoad` | Pause after loading the chat page | 5000 | milliseconds |
| `waitAfterQuestion` | Pause after submitting each question | 10000 | milliseconds |

**Example Scenarios:**

```bash
# performance test: 100 users, 1 minute ramp-up, 10 minutes duration
jmeter -n -t scenarios/ai-assistant.jmx -l reports/performance-test.csv -e -o reports \
  -Jthreads=100 -JrampTime=60 -Jduration=600

# Quick smoke test: 5 users, fast execution
jmeter -n -t scenarios/ai-assistant.jmx -l reports/smoke-test.csv -e -o reports \
  -Jthreads=5 -JrampTime=5 -Jduration=30 -JwaitAfterPageLoad=1000 -JwaitAfterQuestion=2000

# Endurance test: 20 users, 1 hour duration
jmeter -n -t scenarios/ai-assistant.jmx -l reports/endurance-test.csv -e -o reports \
  -Jthreads=20 -JrampTime=60 -Jduration=3600
```

This will:\
- Run the test in non-GUI mode (`-n`)
- Use the specified test plan (`-t`)
- Write results to CSV (`-l`)
- Generate HTML dashboard (`-e -o reports`)
- Set environment variables for local testing

### Generate HTML report from existing CSV file

If you already have a CSV results file and want to generate the HTML dashboard:

```bash
# Generate HTML report from existing CSV
jmeter -g 20260216-164226-ai-assistant-report.csv -o reports
```

This creates the complete HTML dashboard in the `./reports` directory, including:
- `index.html` - Main dashboard with statistics, charts, and error details
- `statistics.json` - Raw statistics data
- Various chart pages and assets

### Important Notes

- The `-e -o` flags will **overwrite** the existing reports directory (use `-f` to force if needed)
- The CSV file **must be in JMeter CSV format** with all required fields
- The JMX file's `ResultCollector` has been configured to:
  - Not create its own CSV file (empty filename)
  - Capture both successes and failures (`success_only_logging=false`)
  - This ensures the command-line CSV contains complete data for report generation

### Troubleshooting Report Generation

**HTML report not generated:**
- Check that the CSV file exists and has data
- Verify the CSV format is correct (should have headers like: timeStamp, elapsed, label, responseCode, success, etc.)
- Ensure the reports directory doesn't exist or use `-f` flag to force overwrite

**Report shows 100% failures when CSV shows successes:**
- This means the HTML report was generated from a different CSV file
- Delete the reports directory and regenerate from the correct CSV file
- Ensure you're using the command-line `-l` flag, not relying on the JMX file's ResultCollector filename

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

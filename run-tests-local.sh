#!/bin/sh
set -x

docker rm -f $(docker ps -aq)
docker compose down -v

docker compose build --no-cache development
docker compose up --wait -d
rm -R ./reports

jmeter -n -t scenarios/ai-assistant.jmx \
  -l reports/test-results.csv \
  -e -o reports \
  -Jenv=local \
  -Jprotocol=http \
  -Jdomain=localhost \
  -Jport=3000 \
  -JagentDomain=localhost \
  -JagentPort=8086 \
  -Jthreads="${THREADS:-2}" \
  -JrampTime="${RAMP_TIME:-30}" \
  -Jduration="${DURATION:-300}" \
  -JhttpTimeout="${HTTP_TIMEOUT:-60000}" \
  -JmaxResponseTime="${MAX_RESPONSE_TIME:-30000}" \
  -JwaitAfterPageLoad="${WAIT_AFTER_PAGE_LOAD:-5000}" \
  -JwaitAfterQuestion="${WAIT_AFTER_QUESTION:-8000}"

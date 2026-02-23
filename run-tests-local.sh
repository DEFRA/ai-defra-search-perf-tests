#!/bin/sh
set -x

docker rm -f $(docker ps -aq)
docker compose build --no-cache development
docker compose up --wait -d
rm -R ./reports

jmeter -n -t scenarios/ai-assistant.jmx \
  -l reports/test-results.csv \
  -e -o reports \
  -Jenv=local \
  -JHTTP_PROTOCOL=http \
  -JAI_DEFRA_SEARCH_FRONTEND_HOST=localhost \
  -JAI_DEFRA_SEARCH_FRONTEND_PORT=3000 \
  -Jthreads=4 \
  -JrampTime=30 \
  -Jduration=300 \
  -JhttpTimeout=60000 \
  -JmaxResponseTime=30000 \
  -JwaitAfterPageLoad=5000 \
  -JwaitAfterQuestion=8000

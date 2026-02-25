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
  -Jprotocol=http \
  -Jdomain=localhost \
  -Jport=3000 \
  -Jthreads=2 \
  -JrampTime=30 \
  -Jduration=300 \
  -JhttpTimeout=60000 \
  -JmaxResponseTime=30000 \
  -JwaitAfterPageLoad=5000 \
  -JwaitAfterQuestion=8000

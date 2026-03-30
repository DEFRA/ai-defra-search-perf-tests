#!/bin/sh
set -x

docker compose down -v

rm -R ./reports

export AGENT_SERVICE_ENDPOINT=localhost
export AGENT_SERVICE_PORT=8086

docker compose run --build --rm development


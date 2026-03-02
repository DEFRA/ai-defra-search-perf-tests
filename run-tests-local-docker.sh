#!/bin/sh
set -x

docker rm -f $(docker ps -aq)
docker compose down -v

rm -R ./reports

docker compose run --build --rm development


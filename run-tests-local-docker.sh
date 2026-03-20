#!/bin/sh
set -x

docker compose down -v

rm -R ./reports

docker compose run --build --rm development


FROM defradigital/cdp-perf-test-docker:latest

RUN apk add --no-cache postgresql-client mongodb-tools

WORKDIR /opt/perftest

COPY scenarios/ ./scenarios/
COPY compose/scripts/ ./scripts/
COPY entrypoint.sh .
COPY user.properties .

RUN chmod +x entrypoint.sh  \
    ./scripts/setup-databases.sh  \
    ./scripts/postgres/init-postgres.sh  \
    ./scripts/mongodb/init-mongodb.sh

ENV S3_ENDPOINT=https://s3.eu-west-2.amazonaws.com
ENV TEST_SCENARIO=ai-assistant

ENTRYPOINT [ "./entrypoint.sh" ]

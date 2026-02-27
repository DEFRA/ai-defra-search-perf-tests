#!/bin/sh
set -x

echo "run_id: $RUN_ID in $ENVIRONMENT"

NOW=$(date +"%Y%m%d-%H%M%S")

if [ -z "${JM_HOME}" ]; then
  JM_HOME=/opt/perftest
fi

JM_SCENARIOS=${JM_HOME}/scenarios
# Use internal dir for JMeter output - bind mount at /opt/perftest/reports causes "Resource busy"
# when -f tries to cleanup; we copy to the mount after
JM_REPORTS_INTERNAL=/tmp/jmeter-reports
JM_REPORTS=${JM_REPORTS_INTERNAL}
JM_REPORTS_OUTPUT=${JM_HOME}/reports
JM_LOGS=${JM_HOME}/logs

mkdir -p ${JM_REPORTS} ${JM_LOGS}

TEST_SCENARIO=${TEST_SCENARIO:-ai-assistant}
SCENARIOFILE=${JM_SCENARIOS}/${TEST_SCENARIO}.jmx
REPORTFILE=${NOW}-perftest-${TEST_SCENARIO}-report.csv
LOGFILE=${JM_LOGS}/perftest-${TEST_SCENARIO}.log

# Before running the suite, replace 'service-name' with the name/url of the service to test.
# ENVIRONMENT is set to the name of th environment the test is running in.
SERVICE_ENDPOINT=${SERVICE_ENDPOINT:-ai-defra-search-frontend.${ENVIRONMENT}.cdp-int.defra.cloud}
# PORT is used to set the port of this performance test container
SERVICE_PORT=${SERVICE_PORT:-443}
SERVICE_URL_SCHEME=${SERVICE_URL_SCHEME:-https}

# Run the test suite
jmeter -n -t ${SCENARIOFILE} -e -l "${REPORTFILE}" -o ${JM_REPORTS} -j ${LOGFILE} -f \
-Jenv="${ENVIRONMENT}" \
-Jdomain="${SERVICE_ENDPOINT}" \
-Jport="${SERVICE_PORT}" \
-Jprotocol="${SERVICE_URL_SCHEME}" \
-Jthreads="${THREADS:-50}" \
-JrampTime="${RAMP_TIME:-10}" \
-Jduration="${DURATION:-120}" \
-JhttpTimeout="${HTTP_TIMEOUT:-30000}" \
-JmaxResponseTime="${MAX_RESPONSE_TIME:-20000}" \
-JwaitAfterPageLoad="${WAIT_AFTER_PAGE_LOAD:-5000}" \
-JwaitAfterQuestion="${WAIT_AFTER_QUESTION:-10000}"
test_exit_code=$?

# Copy to bind-mounted dir for local access (mount at JM_REPORTS_OUTPUT)
if [ -d "${JM_REPORTS_OUTPUT}" ] && [ -f "${JM_REPORTS}/index.html" ]; then
  rm -rf "${JM_REPORTS_OUTPUT:?}"/* 2>/dev/null || true
  cp -r "${JM_REPORTS}"/* "${JM_REPORTS_OUTPUT}/"
fi

# Publish the results into S3 so they can be displayed in the CDP Portal
if [ -n "$RESULTS_OUTPUT_S3_PATH" ]; then
  # Copy the CSV report file and the generated report files to the S3 bucket
   if [ -f "$JM_REPORTS/index.html" ]; then
      aws --endpoint-url=$S3_ENDPOINT s3 cp "$REPORTFILE" "$RESULTS_OUTPUT_S3_PATH/$REPORTFILE"
      aws --endpoint-url=$S3_ENDPOINT s3 cp "$JM_REPORTS" "$RESULTS_OUTPUT_S3_PATH" --recursive
      if [ $? -eq 0 ]; then
        echo "CSV report file and test results published to $RESULTS_OUTPUT_S3_PATH"
      fi
   else
      echo "$JM_REPORTS/index.html is not found"
      exit 1
   fi
else
   echo "RESULTS_OUTPUT_S3_PATH is not set"
   exit 1
fi

exit $test_exit_code

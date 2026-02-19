#!/bin/bash

export AWS_REGION=$AWS_REGION
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_SQS_SECRET_ACCESS_KEY=$AWS_SQS_SECRET_ACCESS_KEY

# S3 buckets
aws --endpoint-url=http://localhost:4566 s3 mb s3://ai-defra-search-ingestion-data

aws --endpoint-url=http://localhost:4566 s3 mb s3://test-results
aws --endpoint-url=http://localhost:4566 sqs create-queue --region $AWS_REGION --queue-name $SQS_CONVERSATION_QUEUE_NAME

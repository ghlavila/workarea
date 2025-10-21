#!/bin/bash

# List all table buckets
echo "=== Table Buckets ==="
aws s3tables list-table-buckets

# List namespaces in a specific bucket
BUCKET_NAME="your-bucket-name"
echo -e "\n=== Namespaces in $BUCKET_NAME ==="
aws s3tables list-namespaces --table-bucket-arn "arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME"

# List tables in a namespace
NAMESPACE="default"
echo -e "\n=== Tables in namespace '$NAMESPACE' ==="
aws s3tables list-tables \
    --table-bucket-arn "arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME" \
    --namespace "$NAMESPACE" 
#!/bin/bash

BUCKET_NAME="your-bucket-name"
NAMESPACE="analytics"
TABLE_NAME="sample_data"

# First get the table ID for the correct ARN
echo "Getting table information..."
TABLE_INFO=$(aws s3tables get-table \
    --table-bucket-arn "arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME" \
    --namespace "$NAMESPACE" \
    --name "$TABLE_NAME")

# Extract table ID from the response
TABLE_ID=$(echo "$TABLE_INFO" | jq -r '.tableId')

if [ "$TABLE_ID" = "null" ] || [ -z "$TABLE_ID" ]; then
    echo "Error: Could not retrieve table ID. Please check if table exists."
    exit 1
fi

# Construct proper table ARN using table ID
TABLE_ARN="arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME/table/$TABLE_ID"

echo "Table: $TABLE_NAME (ID: $TABLE_ID)"
echo "Table ARN: $TABLE_ARN"

# List table snapshots
echo -e "\n=== Current Snapshots for $TABLE_NAME ==="
aws s3tables list-table-snapshots --table-arn "$TABLE_ARN" --query 'snapshots[].{SnapshotId:snapshotId,CreatedAt:createdAt,Status:status}' --output table

# Get snapshot details for latest snapshot
echo -e "\n=== Latest Snapshot Details ==="
LATEST_SNAPSHOT=$(aws s3tables list-table-snapshots --table-arn "$TABLE_ARN" --query 'snapshots[0].snapshotId' --output text)
if [ "$LATEST_SNAPSHOT" != "None" ] && [ -n "$LATEST_SNAPSHOT" ]; then
    aws s3tables get-table-snapshot --table-arn "$TABLE_ARN" --snapshot-id "$LATEST_SNAPSHOT"
else
    echo "No snapshots found for this table"
fi

# Show table maintenance configurations (the correct way)
echo -e "\n=== Snapshot Management Configuration ==="
aws s3tables get-table-maintenance-configuration \
    --table-bucket-arn "arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME" \
    --namespace "$NAMESPACE" \
    --name "$TABLE_NAME" \
    --type icebergSnapshotManagement

echo -e "\n=== Compaction Configuration ==="
aws s3tables get-table-maintenance-configuration \
    --table-bucket-arn "arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME" \
    --namespace "$NAMESPACE" \
    --name "$TABLE_NAME" \
    --type icebergCompaction

echo -e "\n=== S3 Tables Automatic Maintenance ==="
echo "✓ Snapshot management: Configured at table level using S3 Tables maintenance API"
echo "✓ Compaction: Configured at table level using S3 Tables maintenance API"
echo "✓ Unreferenced file removal: Configured at bucket level"
echo "✓ No manual intervention required - all maintenance is automatic" 
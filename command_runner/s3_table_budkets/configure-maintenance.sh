#!/bin/bash

# Script for configuring S3 Table Bucket maintenance settings
# This allows you to customize maintenance beyond the AWS defaults

BUCKET_NAME="your-bucket-name"  # Name of your S3 Table Bucket
NAMESPACE="analytics"
TABLE_NAME="sample_data"

echo "=== S3 Table Bucket Maintenance Configuration ==="
echo "Table Bucket: $BUCKET_NAME"
echo "Table: $NAMESPACE.$TABLE_NAME"
echo ""

# Show current AWS defaults
echo "=== AWS Default Settings (if not configured) ==="
echo "Snapshot Management:"
echo "  - Minimum snapshots to keep: 1"
echo "  - Maximum snapshot age: 120 hours (5 days)"
echo ""
echo "Compaction:"
echo "  - Target file size: 512MB"
echo "  - Configurable range: 64MB - 512MB"
echo ""
echo "Unreferenced File Removal (bucket-level):"
echo "  - Unreferenced days: 3 days"
echo "  - Noncurrent days: 10 days"
echo ""

# Configure snapshot management (table-level)
echo "=== Configuring Snapshot Management ==="
read -p "Enter minimum snapshots to keep (default 5): " MIN_SNAPSHOTS
MIN_SNAPSHOTS=${MIN_SNAPSHOTS:-5}

read -p "Enter maximum snapshot age in hours (default 168 = 7 days): " MAX_AGE_HOURS
MAX_AGE_HOURS=${MAX_AGE_HOURS:-168}

aws s3tables put-table-maintenance-configuration \
    --table-bucket-arn "arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME" \
    --namespace "$NAMESPACE" \
    --name "$TABLE_NAME" \
    --type icebergSnapshotManagement \
    --value '{
        "status": "enabled",
        "settings": {
            "icebergSnapshotManagement": {
                "minSnapshotsToKeep": '"$MIN_SNAPSHOTS"',
                "maxSnapshotAgeHours": '"$MAX_AGE_HOURS"'
            }
        }
    }'

echo "✓ Snapshot management configured: $MIN_SNAPSHOTS min snapshots, $MAX_AGE_HOURS hours max age"

# Configure compaction (table-level)
echo ""
echo "=== Configuring Compaction ==="
read -p "Enter target file size in MB (64-512, default 256): " TARGET_SIZE_MB
TARGET_SIZE_MB=${TARGET_SIZE_MB:-256}

# Validate range
if [ "$TARGET_SIZE_MB" -lt 64 ] || [ "$TARGET_SIZE_MB" -gt 512 ]; then
    echo "Warning: Target file size must be between 64MB and 512MB. Using 256MB."
    TARGET_SIZE_MB=256
fi

aws s3tables put-table-maintenance-configuration \
    --table-bucket-arn "arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME" \
    --namespace "$NAMESPACE" \
    --name "$TABLE_NAME" \
    --type icebergCompaction \
    --value '{
        "status": "enabled",
        "settings": {
            "icebergCompaction": {
                "targetFileSizeMB": '"$TARGET_SIZE_MB"'
            }
        }
    }'

echo "✓ Compaction configured: $TARGET_SIZE_MB MB target file size"

# Configure unreferenced file removal (bucket-level)
echo ""
echo "=== Configuring Unreferenced File Removal (Bucket Level) ==="
read -p "Enter unreferenced days (default 3): " UNREFERENCED_DAYS
UNREFERENCED_DAYS=${UNREFERENCED_DAYS:-3}

read -p "Enter noncurrent days (default 10): " NONCURRENT_DAYS
NONCURRENT_DAYS=${NONCURRENT_DAYS:-10}

aws s3tables put-table-bucket-maintenance-configuration \
    --name "$BUCKET_NAME" \
    --type icebergUnreferencedFileRemoval \
    --value '{
        "status": "enabled",
        "settings": {
            "icebergUnreferencedFileRemoval": {
                "unreferencedDays": '"$UNREFERENCED_DAYS"',
                "nonCurrentDays": '"$NONCURRENT_DAYS"'
            }
        }
    }'

echo "✓ Unreferenced file removal configured: $UNREFERENCED_DAYS unreferenced days, $NONCURRENT_DAYS noncurrent days"

echo ""
echo "=== Configuration Complete ==="
echo "Your S3 Table Bucket maintenance is now configured with custom settings."
echo "These settings will override the AWS defaults for this table and bucket." 
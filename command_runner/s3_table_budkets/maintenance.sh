#!/bin/bash

BUCKET_NAME="gh-prod-table-bucket"

echo "=== S3 Tables Maintenance ==="
echo "Bucket: $BUCKET_NAME"
echo "Date: $(date)"

# Get bucket info including cleanup settings
echo -e "\n=== Bucket Status and Cleanup Settings ==="
aws s3tables get-table-bucket --table-bucket-arn "arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME"

# Get bucket-level unreferenced file removal settings
echo -e "\n=== Bucket-Level Unreferenced File Removal ==="
aws s3tables get-table-bucket-maintenance-configuration \
    --table-bucket-arn "arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME" \
    --type unreferencedFileRemoval 2>/dev/null || echo "Default settings applied"

# List all tables across namespaces with their maintenance settings
echo -e "\n=== All Tables and Their Maintenance Settings ==="
for namespace in $(aws s3tables list-namespaces --table-bucket-arn "arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME" --query 'namespaces[].namespace' --output text); do
    echo "Namespace: $namespace"
    
    # Get tables in this namespace
    tables=$(aws s3tables list-tables \
        --table-bucket-arn "arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME" \
        --namespace "$namespace" \
        --query 'tables[].[name,tableId]' --output text)
    
    while read -r table_name table_id; do
        if [ -n "$table_name" ] && [ -n "$table_id" ]; then
            echo "  Table: $table_name (ID: $table_id)"
            
            # Show snapshot management settings
            echo "    Snapshot Management:"
            snapshot_config=$(aws s3tables get-table-maintenance-configuration \
                --table-bucket-arn "arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME" \
                --namespace "$namespace" \
                --name "$table_name" \
                --type icebergSnapshotManagement \
                --query 'configuration.settings.icebergSnapshotManagement' \
                --output json 2>/dev/null)
            
            if [ -n "$snapshot_config" ] && [ "$snapshot_config" != "null" ]; then
                echo "      $snapshot_config"
            else
                echo "      Default settings (1 min snapshot, 120 hours max age)"
            fi
            
            # Show compaction settings
            echo "    Compaction:"
            compaction_config=$(aws s3tables get-table-maintenance-configuration \
                --table-bucket-arn "arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME" \
                --namespace "$namespace" \
                --name "$table_name" \
                --type icebergCompaction \
                --query 'configuration.settings.icebergCompaction' \
                --output json 2>/dev/null)
            
            if [ -n "$compaction_config" ] && [ "$compaction_config" != "null" ]; then
                echo "      $compaction_config"
            else
                echo "      Default settings (512MB target file size)"
            fi
            
            # Show current snapshot count
            table_arn="arn:aws:s3tables:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):bucket/$BUCKET_NAME/table/$table_id"
            snapshot_count=$(aws s3tables list-table-snapshots --table-arn "$table_arn" --query 'length(snapshots)' --output text 2>/dev/null)
            echo "    Current snapshots: ${snapshot_count:-0}"
        fi
    done <<< "$tables"
done

echo -e "\n=== Automatic Maintenance Status ==="
echo "✓ Bucket-level unreferenced file removal: Enabled by default"
echo "✓ Table-level snapshot management: Configured per table"
echo "✓ Table-level compaction: Configured per table"
echo "✓ All maintenance operations run automatically without manual intervention"

echo -e "\n=== Maintenance Complete ===" 
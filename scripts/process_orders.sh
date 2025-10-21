#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <directory_path>"
    echo "Set DRY_RUN=1 to preview commands"
    exit 1
fi

directory="$1"

run_cmd() {
    if [ "${DRY_RUN:-0}" = "1" ]; then
        echo "Would run: $*"
    else
        "$@"
    fi
}

# Find all .sql3 files in the directory
for sqlite_file in "$directory"/*.sql3; do
    if [ ! -f "$sqlite_file" ]; then
        echo "No .sql3 files found in $directory"
        exit 0
    fi

    # Extract base name without .sql3 extension
    orders=$(basename "$sqlite_file" .sql3)

    # Skip specific files
    if [[ "$orders" =~ ^(gv|gh|gh_maps)$ ]]; then
        echo "Skipping $orders..."
        continue
    fi

    echo "Processing $orders..."

    # 1. Create partitioned table
    run_cmd /query_engine/bin/order_tool create-table \
        --table-name "$orders" \
        --location s3://gh-prod-orders/$orders/ \
        --partition \
        --database gh_prod_orders \
        --s3-temp s3://gh-data-proc/athena/output/junk_bucket/

    # 2. Process SQLite data
    run_cmd /query_engine/bin/order_tool process \
        --sqlite-file "${directory}/${orders}.sql3" \
        --location s3://gh-prod-orders/$orders/ \
        --partition

    # 3. Repair table
    run_cmd /query_engine/bin/order_tool repair \
        --table-name "$orders" \
        --database gh_prod_orders \
        --s3-temp s3://gh-data-proc/athena/output/junk_bucket/

    echo "Completed processing $orders"
done

echo "All files processed"

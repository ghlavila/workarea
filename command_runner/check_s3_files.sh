#!/bin/bash

#  check if files exist in S3 locations
# Usage: ./check_s3_files.sh --s3bucket BUCKET --s3key KEY

set -e

# Initialize variables
S3_BUCKET=""
S3_KEY=""

# Function to display usage
usage() {
    echo "Usage: $0 --s3bucket S3_BUCKET --s3key S3_KEY"
    echo ""
    echo "Arguments:"
    echo "  --s3bucket     S3 bucket name"
    echo "  --s3key        S3 key/path to check for files"
    echo ""
    echo "Examples:"
    echo "  $0 --s3bucket gh-prod-cdc-myclient --s3key gv/xfer/in/20250712/"
    echo "  $0 --s3bucket gh-prod-cdc-myclient --s3key gv/xfer/in/filename.csv"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --s3bucket)
            S3_BUCKET="$2"
            shift 2
            ;;
        --s3key)
            S3_KEY="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$S3_BUCKET" || -z "$S3_KEY" ]]; then
    echo "Error: Missing required arguments --s3bucket and --s3key"
    usage
fi

# Function to check if S3 path has files
check_s3_path() {
    local s3_path="$1"
    local description="$2"
    
    echo "Checking $description: $s3_path"
    
    # Use aws s3 ls to check if path has files
    local output=$(aws s3 ls "$s3_path" 2>/dev/null)
    
    if [[ -n "$output" ]]; then
        echo "✓ Found files in: $s3_path"
        return 0
    else
        echo "✗ No files found in: $s3_path"
        return 1
    fi
}

# Construct S3 path
S3_PATH="s3://${S3_BUCKET}/${S3_KEY}"

# Check if S3 path exists and has files
if ! check_s3_path "$S3_PATH" "S3 location"; then
    exit 1
fi

# Final result
echo ""
echo "SUCCESS: Files found in S3 location"
exit 0
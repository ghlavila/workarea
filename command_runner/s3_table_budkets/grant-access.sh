#!/bin/bash

# AWS managed S3 Tables policies
FULL_ACCESS_POLICY="arn:aws:iam::aws:policy/AmazonS3TablesFullAccess"
READONLY_POLICY="arn:aws:iam::aws:policy/AmazonS3TablesReadOnlyAccess"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <user-name> [user|role] [full|readonly]"
    echo "Examples:"
    echo "  $0 my-admin-user user full"
    echo "  $0 my-read-user user readonly"
    echo "  $0 AdminRole role full"
    exit 1
fi

TARGET_NAME=$1
TARGET_TYPE=${2:-user}
ACCESS_LEVEL=${3:-full}

# Select policy based on access level
if [ "$ACCESS_LEVEL" = "readonly" ]; then
    POLICY_ARN=${READONLY_POLICY}
    echo "Granting READ-ONLY access to S3 Tables"
else
    POLICY_ARN=${FULL_ACCESS_POLICY}
    echo "Granting FULL access to S3 Tables"
fi

echo "Using policy: $POLICY_ARN"
echo "Target: $TARGET_TYPE '$TARGET_NAME'"

if [ "$TARGET_TYPE" = "user" ]; then
    aws iam attach-user-policy \
        --user-name "$TARGET_NAME" \
        --policy-arn "$POLICY_ARN"
elif [ "$TARGET_TYPE" = "role" ]; then
    aws iam attach-role-policy \
        --role-name "$TARGET_NAME" \
        --policy-arn "$POLICY_ARN"
else
    echo "❌ Error: TARGET_TYPE must be 'user' or 'role'"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "✅ Policy attached successfully to $TARGET_TYPE: $TARGET_NAME"
else
    echo "❌ Failed to attach policy to $TARGET_TYPE: $TARGET_NAME"
fi

# usage
# Grant full access
#./grant-access.sh john-admin user full

# Grant read-only access  
#./grant-access.sh analyst-user user readonly
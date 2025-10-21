#!/bin/bash

set -e  # Exit on error

GITHUB_REPO=git@github.com:Growth-Health/data_processing.git

# Retrieve secret
SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id command-runner-deployment-config \
    --region us-east-1 \
    --query SecretString \
    --output text 2>&1)

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to retrieve secret from Secrets Manager"
    echo "${SECRET_JSON}"
    exit 1
fi

# Parse JSON and extract values
VPC_ID=$(echo "${SECRET_JSON}" | jq -r '.vpc_id')
SUBNET_ID=$(echo "${SECRET_JSON}" | jq -r '.subnet_id')
GITHUB_DEPLOY_KEY_SECRET_ARN=$(echo "${SECRET_JSON}" | jq -r '.github_deploy_key_secret_arn')
EFS_FILESYSTEM_ID=$(echo "${SECRET_JSON}" | jq -r '.efs_filesystem_id')
SECURITY_GROUP_ID_1=$(echo "${SECRET_JSON}" | jq -r '.security_group_id_1')
SECURITY_GROUP_ID_2=$(echo "${SECRET_JSON}" | jq -r '.security_group_id_2')

# Validate that values were extracted
if [ -z "${VPC_ID}" ] || [ "${VPC_ID}" = "null" ]; then
    echo "ERROR: vpc_id not found in secret"
    exit 1
fi

echo "Retrieved values..."
echo "=========================================="
echo ""
echo "Network Configuration:"
echo "  VPC ID: ${VPC_ID}"
echo "  Subnet ID: ${SUBNET_ID}"
echo ""
echo "Security Groups:"
echo "  Security Group 1: ${SECURITY_GROUP_ID_1}"
echo "  Security Group 2: ${SECURITY_GROUP_ID_2}"
echo ""
echo "Storage:"
echo "  EFS Filesystem ID: ${EFS_FILESYSTEM_ID}"
echo ""
echo "Secrets:"
echo "  GitHub Deploy Key ARN: ${GITHUB_DEPLOY_KEY_SECRET_ARN}"
echo "  GitHub repo: ${GITHUB_REPO}"
echo ""
echo "=========================================="
echo ""
echo "✓ Successfully retrieved and parsed all configuration values!"
echo ""
echo "Next Steps:"
echo "  1. Verify the values above are correct"
echo "  2. Proceed to Phase 3: Update CloudFormation templates"
echo "  3. Add deployment logic to this script"
echo ""

# echo "Deploying CloudFormation stack..."
# aws cloudformation deploy \
#   --template-file command_runner.yaml \
#   --stack-name command-runner \
#   --region us-east-1 \
#   --capabilities CAPABILITY_NAMED_IAM \
#   --parameter-overrides \
#     VpcId=${VPC_ID} \
#     SubnetId=${SUBNET_ID} \
#     GitHubRepoUrl=${GITHUB_REPO} \
#     GitHubDeployKeySecretArn=${GITHUB_SECRET}

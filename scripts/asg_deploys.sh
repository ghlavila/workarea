#!/bin/bash

# Check if argument is provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide an environment argument (dev or prod)"
    echo "Usage: $0 <dev|prod>"
    exit 1
fi

# Get the environment argument and convert to lowercase
ENV=$(echo "$1" | tr '[:upper:]' '[:lower:]')

# Validate the environment argument
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Error: Invalid environment '$1'. Please use 'dev' or 'prod'"
    echo "Usage: $0 <dev|prod>"
    exit 1
fi

# Execute the appropriate command based on environment
ASG_NAME="gh-${ENV}-query-engine-asg"
echo "Starting instance refresh for $ENV environment (ASG: $ASG_NAME)..."

# Capture the JSON output from the AWS command
RESULT=$(aws autoscaling start-instance-refresh --auto-scaling-group-name "$ASG_NAME" 2>&1)
EXIT_CODE=$?

# Check if the command was successful
if [ $EXIT_CODE -eq 0 ]; then
    # Parse the instance refresh ID from the JSON response
    INSTANCE_REFRESH_ID=$(echo "$RESULT" | grep -o '"InstanceRefreshId": "[^"]*"' | cut -d'"' -f4)
    
    echo "✓ Successfully started instance refresh for $ASG_NAME"
    echo "Instance Refresh ID: $INSTANCE_REFRESH_ID"
    echo ""
    echo "You can monitor the progress with:"
    echo "aws autoscaling describe-instance-refreshes --auto-scaling-group-name $ASG_NAME --instance-refresh-ids $INSTANCE_REFRESH_ID"
    echo ""
    echo "Or check all refreshes for this ASG:"
    echo "aws autoscaling describe-instance-refreshes --auto-scaling-group-name $ASG_NAME"
else
    echo "✗ Error: Failed to start instance refresh for $ASG_NAME"
    echo "AWS CLI output:"
    echo "$RESULT"
    exit 1
fi

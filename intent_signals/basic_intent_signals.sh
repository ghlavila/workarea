#!/bin/bash 

# Create payload JSON 
PAYLOAD='{
   "instance_name": "Intent-Signals-daily-build",
   "instance_type": "i4i.24xlarge",
   "config": "/sdata/opt/command-runner/code/intent_signals/main.yaml",
   "client_id": "stirista",
   "table": "intent_signals"
}'

# Display payload contents before execution
echo "About to invoke Lambda function with the following payload:"
echo "$PAYLOAD" | jq .

read -p "Do you want to continue? (y/n): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

aws lambda invoke \
    --function-name command-runner-CommandRunnerLaunchFunction-jFD7ESILSR9s \
    --cli-binary-format raw-in-base64-out \
    --no-cli-pager \
    --payload "$PAYLOAD" \
    /dev/null    

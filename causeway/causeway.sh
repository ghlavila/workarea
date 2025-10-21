#!/bin/bash 

# Create payload JSON 
PAYLOAD='{
   "instance_name": "Statara-data-proc",
   "instance_type": "c6id.24xlarge",
   "config": "/sdata/opt/command-runner/code/st/st_data_proc.yaml",
   "client_id": "statara",
   "table": "st",
   "run_date": "20250703"
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

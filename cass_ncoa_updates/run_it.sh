#!/bin/bash 

# Create payload JSON 
PAYLOAD='{
   "instance_name": "cass-ncoa-update",
   "instance_type": "t2.micro",
   "config": "/sdata/opt/command-runner/code/cass_ncoa_updates/cass_ncoa_updates.yaml",
   "client_id": "growth_verticals",
   "table": "cass_ncoa_updates"
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

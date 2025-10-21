#!/bin/bash

# install session manager if not installed
# only need this if running from an ec2
#rpm -qa | grep session-manager || sudo yum install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm

# Fetch all running EC2 instances with their instance IDs and names, and sort them by name
instances=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[InstanceId, Tags[?Key==`Name`].Value | [0]]' \
    --output text | sort -k2)

# Initialize an array to hold instance IDs and names
declare -a instance_ids
declare -a instance_names

# Initialize a counter for assigning letters
counter=0

# Function to convert a number to a lowercase letter (a-z)
num_to_letter() {
    local num=$1
    echo $(printf "\x$(printf %x $((97 + $num)))")
}

# Display instances with a letter preceding them
echo "Available Running EC2 Instances:"
while IFS= read -r line; do
    instance_id=$(echo $line | awk '{print $1}')
    instance_name=$(echo $line | awk '{print $2}')

    # Add to arrays
    instance_ids+=("$instance_id")
    instance_names+=("$instance_name")

    # Get the corresponding letter
    letter=$(num_to_letter $counter)
    
    # Display the instance with the letter
    echo "$letter) $instance_name ($instance_id)"
    
    # Increment counter
    ((counter++))
done <<< "$instances"

# Prompt the user to select an instance
read -p "Select an instance by letter: " selection

# Convert the letter back to a number
selected_index=$(($(printf "%d" "'$selection") - 97))

# Get the selected instance ID
selected_instance_id=${instance_ids[$selected_index]}

# Connect to the selected instance using AWS Session Manager
echo "Connecting to ${instance_names[$selected_index]} ($selected_instance_id)..."
aws ssm start-session --target $selected_instance_id


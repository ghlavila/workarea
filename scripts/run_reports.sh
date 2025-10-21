#!/bin/bash

execute_command() {
  local command=("$@")
  echo "Built command: ${command[@]}"
  "${command[@]}"
  if [ $? -ne 0 ]; then
    echo "Command failed: ${command[@]}"
    exit 1
  fi
}

client=horacemann
run_date=20250331

# need to mount bucket
/data/git/data_processing/scripts/mount_buckets gh-prod-cdc-$client
# and mkdir -p the reports dir

results_path="/gh_prod_cdc_$client]/gv/data-proc/reports/$run_date"
mkdir -p $results_path

junk_bucket="s3://gh-data-proc/athena/output/junk_bucket/"
ses_mail="/data/git/data_processing/scripts/ses_mail.py"


read -r -d '' query <<EOF
select * from hm_campaign_analysis limit 10 
EOF

read -r -d '' query2 <<EOF
select * from hm_campaign_analysis limit 10 
EOF

read -r -d '' query3 <<EOF
select * from hm_campaign_analysis limit 10 
EOF

# Create an array of queries
queries=("$query" "$query2" "$query3")

# Loop through each query
for i in "${!queries[@]}"; do
    # Create command with current query
    create_command=("aws_tool" "athena" "-d" "gh_data" "-q" "${queries[$i]}" "-l" -o "$results_path/filename_$i.csv" -l "$junk_bucket")
    execute_command "${create_command[@]}"

done


ses_mail --sender bsmith@growthverticals.com --recipient recipient@example.com,r2.example.py --subject "Test" --body "Test body" --file-paths $results_path/file.csv

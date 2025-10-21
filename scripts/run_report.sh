#!/bin/bash
#
export RUST_LOG=info
~/src/rust/dp_tools/target/release/report_tool report -b gh_data -t s3://gh-rsk-testing/athena-temp/ -e pd_all_encounters_20250528 -d "date_parse(start_service_date,'%Y%m%d')" -a charge_amt -g geo_master_20250504 > pd_report.json

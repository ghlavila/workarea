#!/usr/bin/env python3
"""
Simple script to execute queries using Athena.
"""

import argparse
import subprocess
import sys


def execute_query(sql_query, region, output_location):
    """Execute query using Athena."""
    
    # Execute query using Athena - let the query specify fully qualified table names
    result = subprocess.run([
        'aws', 'athena', 'start-query-execution',
        '--query-string', sql_query,
        '--result-configuration', f'OutputLocation={output_location}',
        '--region', region
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        print("✅ Query executed successfully")
        if result.stdout:
            print(result.stdout)
    else:
        print(f"❌ Error: {result.stderr}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description='Execute queries using Athena')
    
    # Create mutually exclusive group for query input
    query_group = parser.add_mutually_exclusive_group(required=True)
    query_group.add_argument('--sql-file', help='SQL query file path')
    query_group.add_argument('--query', help='SQL query string')
    
    parser.add_argument('--output-location', default='s3://gh-data-proc/athena/output/junk_bucket/', help='S3 location for query results (default: s3://gh-data-proc/athena/output/junk_bucket/)')
    parser.add_argument('--region', default='us-east-1', help='AWS region (default: us-east-1)')
    
    args = parser.parse_args()
    
    # Get SQL query from file or direct input
    if args.sql_file:
        with open(args.sql_file, 'r') as f:
            sql_query = f.read().strip()
    else:
        sql_query = args.query.strip()
    
    if not sql_query:
        print("❌ SQL query is empty")
        sys.exit(1)
    
    # Execute query
    execute_query(sql_query, args.region, args.output_location)


if __name__ == "__main__":
    main()

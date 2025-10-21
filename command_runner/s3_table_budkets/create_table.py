#!/usr/bin/env python3
"""
Simple script to create S3 Tables from SQL DDL files.
"""

import argparse
import json
import re
import subprocess
import sys


def parse_sql_to_fields(sql_content):
    """Extract table name and fields from SQL DDL."""
    # Get table name (handle CREATE EXTERNAL TABLE IF NOT EXISTS as well)
    table_match = re.search(r'CREATE\s+(?:EXTERNAL\s+)?TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)', sql_content, re.IGNORECASE)
    table_name = table_match.group(1) if table_match else None
    
    # Find first opening parenthesis after table name
    start_paren = sql_content.find('(')
    if start_paren == -1:
        return None, []
    
    # Find matching closing parenthesis
    paren_count = 0
    end_paren = -1
    for i in range(start_paren, len(sql_content)):
        if sql_content[i] == '(':
            paren_count += 1
        elif sql_content[i] == ')':
            paren_count -= 1
            if paren_count == 0:
                end_paren = i
                break
    
    if end_paren == -1:
        return None, []
    
    # Extract columns text between parentheses
    columns_text = sql_content[start_paren + 1:end_paren]
    
    # Parse each column line
    fields = []
    for line in columns_text.split(','):
        line = line.strip()
        if not line:
            continue
            
        parts = line.split()
        if len(parts) >= 2:
            name = parts[0]
            data_type = parts[1]
            required = 'NOT NULL' in line.upper()
            
            # Convert SQL types to Iceberg types
            if data_type.lower().startswith(('varchar', 'char')):
                data_type = 'string'
            elif data_type.lower() in ('int', 'integer'):
                data_type = 'int'
            elif data_type.lower() == 'bigint':
                data_type = 'long'
            
            fields.append({
                "name": name,
                "type": data_type,
                "required": required
            })
    
    return table_name, fields


def create_table(bucket_name, namespace, table_name, fields, region, account_id):
    """Create table using AWS CLI."""
    # Build metadata JSON
    metadata = {
        "iceberg": {
            "schema": {
                "fields": fields
            }
        }
    }
    
    bucket_arn = f"arn:aws:s3tables:{region}:{account_id}:bucket/{bucket_name}"

    # Create table
    result = subprocess.run([
        'aws', 's3tables', 'create-table',
        '--table-bucket-arn', bucket_arn,
        '--namespace', namespace,
        '--name', table_name,
        '--format', 'ICEBERG',
        '--metadata', json.dumps(metadata)
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        print(f"✅ Table '{table_name}' created in bucket '{bucket_name}', namespace '{namespace}'")
    else:
        print(f"❌ Error: {result.stderr}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='Create S3 Tables from SQL DDL files')
    parser.add_argument('--bucket-name', required=True, help='S3 Table Bucket name')
    parser.add_argument('--namespace', required=True, help='Namespace name')
    parser.add_argument('--sql-file', required=True, help='SQL DDL file path')
    parser.add_argument('--account-id', default='716531470317', help='AWS account ID (default: 716531470317)')
    parser.add_argument('--region', default='us-east-1', help='AWS region (default: us-east-1)')
    
    args = parser.parse_args()
    
    # Read SQL file
    with open(args.sql_file, 'r') as f:
        sql_content = f.read()
    
    # Parse SQL
    table_name, fields = parse_sql_to_fields(sql_content)
    
    if not table_name or not fields:
        print("❌ Could not parse SQL file")
        sys.exit(1)
    
    # Create table
    create_table(args.bucket_name, args.namespace, table_name, fields, args.region, args.account_id)


if __name__ == "__main__":
    main() 

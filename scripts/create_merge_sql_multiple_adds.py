#!/usr/bin/python3
import boto3
import argparse
import time


def get_table_schema(client, database, table):
    query = f"DESCRIBE {database}.{table}"
    print(f"Executing query: {query}")
    
    response = client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={'Database': database},
        ResultConfiguration={'OutputLocation': 's3://gh-data-proc/athena/output/junk_bucket/'}
    )
    query_execution_id = response['QueryExecutionId']
    
    # Wait for the query to complete
    while True:
        query_status = client.get_query_execution(QueryExecutionId=query_execution_id)
        status = query_status['QueryExecution']['Status']['State']
        if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            break
        time.sleep(1)
    
    if status != 'SUCCEEDED':
        raise Exception(f"Query failed with status: {status}")
    
    # Get the results
    result = client.get_query_results(QueryExecutionId=query_execution_id)
    schema = []
    
    # Flag to track if we've started processing actual column rows
    processing = False
    
    print("\nDEBUG: Starting schema processing:")
    # Process all rows
    for row in result['ResultSet']['Rows']:  # Process all rows, including first row
        col_info = row['Data'][0]['VarCharValue'].strip()
        print(f"Processing: '{col_info}'")
        
        # Skip empty lines
        if not col_info:
            print("  Skipping empty line")
            continue
            
        # If we hit a # while processing, we're done
        if col_info.startswith('#') and processing:
            print("  Found end marker, stopping")
            break
            
        # Skip any # lines before we start processing
        if col_info.startswith('#'):
            print("  Skipping header line")
            continue
            
        # We've found our first valid column row
        processing = True
        
        # Process column info
        try:
            parts = col_info.split('\t')
            col_name = parts[0].strip('`').strip()
            if col_name:
                schema.append(col_name)
                print(f"  Added column: {col_name}")
        except Exception as e:
            print(f"  Error processing row: {e}")
    
    return schema

def generate_alter_table_sql(primary_table, secondary_table_schema, primary_table_schema):
    alter_statements = []
    for column in secondary_table_schema:
        if column not in primary_table_schema:
            alter_statements.append(f"ALTER TABLE {primary_table} ADD COLUMN {column} STRING;")
    return alter_statements

def generate_merge_sql(primary_table, secondary_table, primary_table_schema, secondary_table_schema):
    # Format each column on a new line
    columns = []
    values = []
    updates = []
    
    # Find columns unique to secondary table (these need to be updated when matched)
    unique_to_secondary = [col for col in secondary_table_schema if col not in primary_table_schema]
    
    # Process all columns in primary table
    for col in primary_table_schema:
        columns.append(col)
        # If column exists in secondary, use its value; otherwise, use empty string
        if col in secondary_table_schema:
            values.append(f'b.{col}')
        else:
            values.append("''")
    
    # Generate update statements for columns unique to secondary
    if unique_to_secondary:
        updates = [f"{col} = b.{col}" for col in unique_to_secondary]
    
    columns_formatted = ',\n        '.join(columns)
    values_formatted = ',\n        '.join(values)
    updates_formatted = ',\n        '.join(updates)
    
    merge_sql = f"""
    MERGE INTO {primary_table} a
    USING {secondary_table} b
    ON a.mpid = b.mpid"""

    # Only add WHEN MATCHED clause if we have columns to update
    if updates:
        merge_sql += f"""
    WHEN MATCHED THEN
    UPDATE SET
        {updates_formatted}"""

    merge_sql += f"""
    WHEN NOT MATCHED THEN
    INSERT (
        {columns_formatted}
    )
    VALUES (
        {values_formatted}
    );
    """
    return merge_sql

def main():
    parser = argparse.ArgumentParser(description='Merge two Athena tables.')
    parser.add_argument('--primary-table', required=True, help='The primary table name')
    parser.add_argument('--secondary-table', required=True, help='The secondary table name')
    parser.add_argument('--database', required=True, help='The Athena database name')
    args = parser.parse_args()

    client = boto3.client('athena')

    primary_table_schema = get_table_schema(client, args.database, args.primary_table)
    print("Primary table schema:", primary_table_schema)
    secondary_table_schema = get_table_schema(client, args.database, args.secondary_table)
    print("Secondary table schema:", secondary_table_schema)

    alter_statements = generate_alter_table_sql(args.primary_table, secondary_table_schema, primary_table_schema)
    merge_sql = generate_merge_sql(args.primary_table, args.secondary_table, primary_table_schema, secondary_table_schema)

    # Combine all SQL statements into one stream
    full_sql = "\n".join(alter_statements) + "\n" + merge_sql

    print("Generated SQL statements:")
    print(full_sql)

if __name__ == '__main__':
    main()
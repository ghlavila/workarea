# Growth Verticals Data Processing

Data processing requires various specific environment settings. [details to follow]


## Current 3'rd party data sources:

### Quaterly

1.) AIQ - household leve data <br>
2.) AIQ - zip+4 level data [not currently used] <br>
3.) AIQ - business to business data <br>
4.) Healthwise - consumer level data <br>

This data is uploaded to the provider's SFTP server <br>


### Monthly

1.) Statara - digital campaign data <br>
2.) Statara - Political data <br>
3.) Stirista - [may replace Statara for digital campaigns <br>

This data is uploaded to the provider's s3 bucket <br>


The sources below do not have an establised delivery schedule: <br>

1.) CML Nurse data<br>
2.) LS Corp<br>
3.) Causeway<br>


## current client data 

1.) Horace Mann <br>
2.) Platinum Dermatology <br>


Statara/Popsycle also provides data daily for intent-triggers and campaign ad-log data

# S3 Table Buckets Basic Setup and Maintenance

This repository contains CloudFormation templates and scripts for managing **AWS S3 Table Buckets** with proper automatic maintenance configuration.

## Important: S3 Table Buckets vs General Purpose Buckets

This project is specifically for **S3 Table Buckets** - a new bucket type designed for analytics workloads with built-in Apache Iceberg support and automatic maintenance.

**❌ NOT for:** Self-managed Iceberg tables in general purpose S3 buckets
**✅ FOR:** Tables stored in AWS S3 Table Buckets with automatic maintenance

## S3 Table Bucket Maintenance Defaults

S3 Table Buckets come with automatic maintenance **enabled by default**, but you may want to customize these settings:

### Default Settings (if not configured)

| Maintenance Type | Parameter | Default Value | Configurable Range | Configuration Level |
|------------------|-----------|---------------|-------------------|---------------------|
| **Snapshot Management** | Minimum snapshots | 1 | 1+ | Table level |
| **Snapshot Management** | Maximum age | 120 hours (5 days) | 1+ hours | Table level |
| **Compaction** | Target file size | 512MB | 64MB - 512MB | Table level |
| **Unreferenced File Removal** | Unreferenced days | 3 days | 1+ days | Bucket level |
| **Unreferenced File Removal** | Noncurrent days | 10 days | 1+ days | Bucket level |

### When You Might Want to Change Defaults

- **Snapshot Management**: If you need longer retention for compliance or want more aggressive cleanup
- **Compaction**: Smaller files (64-256MB) for frequent small writes, larger files (512MB) for batch processing
- **Unreferenced File Removal**: Adjust based on your data lifecycle requirements

## How S3 Table Bucket Maintenance Works

Based on [AWS S3 Table Buckets documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-tables-maintenance.html), here's how maintenance works for tables in table buckets:

### Maintenance Configuration Levels (Table Buckets Only)

- **Compaction**: Can ONLY be configured at the **table level** (within table buckets)
- **Snapshot Management**: Can ONLY be configured at the **table level** (within table buckets)
- **Unreferenced File Removal**: Can ONLY be configured at the **table bucket level**

### ❌ What DOESN'T Work with S3 Table Buckets

Table buckets do **NOT support** standard Iceberg table properties for retention:
```bash
# ❌ This DOESN'T work with tables in S3 Table Buckets
--table-properties '{
    "history.expire.max-snapshot-age-ms": "604800000",
    "history.expire.min-snapshots-to-keep": "5"
}'
```

### ✅ What DOES Work with S3 Table Buckets

Use S3 Table Buckets maintenance configuration API:
```bash
# ✅ This is the correct way for tables in table buckets
aws s3tables put-table-maintenance-configuration \
    --table-bucket-arn "arn:aws:s3tables:region:account:bucket/bucket-name" \
    --namespace "namespace-name" \
    --name "table-name" \
    --type icebergSnapshotManagement \
    --value '{
        "status": "enabled",
        "settings": {
            "icebergSnapshotManagement": {
                "minSnapshotsToKeep": 5,
                "maxSnapshotAgeHours": 168
            }
        }
    }'
```

## Files Overview

### CloudFormation Template
- `basic-s3tables-role.yaml` - Creates IAM roles for S3 Table Buckets access (using s3tables namespace)

### Scripts (All specific to S3 Table Buckets)
- `create_table.py` - **Python script** for creating tables from SQL DDL statements (focused on table creation only)
- `create-table.sh` - Bash script for creating tables with JSON schema support (legacy/alternative)
- `configure-maintenance.sh` - Interactive script to configure custom maintenance settings
- `view-snapshots.sh` - Views snapshots and maintenance settings for tables in table buckets
- `grant-access.sh` - Grants access using correct table bucket ARN format
- `list-resources.sh` - Lists S3 Table Buckets resources
- `maintenance.sh` - Shows comprehensive maintenance status for table buckets

### Schema Files
- `schemas/daily_sales.sql` - Example SQL DDL for sales data table
- `schemas/user_events.sql` - Example SQL DDL for event tracking with NOT NULL constraints
- `schemas/users-schema.json` - Example JSON schema for user data table (legacy)
- `schemas/events-schema.json` - Example JSON schema for event tracking table (legacy)

## Key Features of S3 Table Buckets (vs General Purpose Buckets)

1. **Table ARN Format**: Uses table ID in s3tables namespace
   ```
   arn:aws:s3tables:region:account:bucket/bucket-name/table/table-id
   ```

2. **Automatic Maintenance**: Built-in compaction, snapshot management, unreferenced file removal

3. **Service Namespace**: Uses `s3tables` (not `s3`) for all operations

4. **Performance Benefits**: Up to 3x query performance improvement vs self-managed tables

## Usage

1. Deploy CloudFormation stack for table bucket access:
```bash
aws cloudformation create-stack \
    --stack-name s3table-buckets-roles-dev \
    --template-body file://basic-s3tables-role.yaml \
    --parameters ParameterKey=ProjectName,ParameterValue=analytics \
                 ParameterKey=Environment,ParameterValue=dev \
    --capabilities CAPABILITY_NAMED_IAM
```

2. Create tables from SQL DDL statements (recommended):

   **Using SQL file:**
   ```bash
   python3 create_table.py -b my-table-bucket -s schemas/daily_sales.sql
   ```

   **Using inline SQL:**
   ```bash
   python3 create_table.py -b my-table-bucket --sql "CREATE TABLE users (id long NOT NULL, name string NOT NULL, created_at timestamp)"
   ```

   **Dry run to see parsed schema:**
   ```bash
   python3 create_table.py -b my-table-bucket -s schemas/user_events.sql --dry-run -v
   ```

   **Legacy JSON schema approach:**
   ```bash
   ./create-table.sh -b my-table-bucket -t users -s schemas/users-schema.json
   ```

3. Configure custom maintenance settings interactively:
```bash
./configure-maintenance.sh
```

4. Update table bucket names in scripts and run them as needed.

## SQL DDL Schema Definition (Recommended)

The Python script parses standard SQL DDL statements and automatically converts them to the required S3 Tables format.

**Supported SQL DDL format:**
```sql
CREATE TABLE table_name (
    field1 type1,
    field2 type2 NOT NULL,
    field3 decimal(10,2),
    ...
)
[PARTITIONED BY (partition_expression)]
[TBLPROPERTIES (...)]
```

**Supported data types:**
- `string`, `varchar(n)`, `char(n)`, `text` → `string`
- `int`, `integer` → `int`
- `bigint`, `long` → `long`
- `float` → `float`
- `double` → `double`
- `boolean`, `bool` → `boolean`
- `date` → `date`
- `timestamp`, `timestamptz` → `timestamp`
- `decimal(precision,scale)` → `decimal(precision,scale)`
- `binary` → `binary`
- `uuid` → `uuid`

**Features:**
- Automatically extracts table name from SQL
- Converts `NOT NULL` constraints to `required: true`
- Handles partitioning expressions (stored for reference)
- Ignores comments and TBLPROPERTIES
- Supports complex types like `decimal(10,2)`

## Legacy JSON Schema Definition

For the bash script, schemas use JSON format:
```json
{
  "fields": [
    {
      "name": "field_name",
      "type": "field_type",
      "required": true|false
    }
  ]
}
```

## References

- [S3 Table Buckets Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-tables.html)
- [S3 Table Buckets Maintenance](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-tables-maintenance.html)
- [Access Management for S3 Table Buckets](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-tables-setting-up.html)
- [S3 Tables Performance Blog](https://aws.amazon.com/blogs/storage/how-amazon-s3-tables-use-compaction-to-improve-query-performance-by-up-to-3-times/)

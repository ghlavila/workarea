CREATE TABLE stirista_master_20250218
WITH (
    format = 'PARQUET',
    external_location = 's3://your-bucket/path/to/data/'
) AS
SELECT
    b.mpid,
    a.zip11 as stirista_hh_id,
    a.*
FROM raw_data_20250218 a
INNER JOIN master_20241117 b
    ON a.zip11 = concat(b.zip,b.zip4,substr(b.dpc,1,2))
WHERE a.digital_flag = 'Y'


---- to set more properties

CREATE TABLE stirista_master_20250218
WITH (
    format = 'PARQUET',
    external_location = 's3://your-bucket/path/to/data/',
    partitioned_by = ARRAY['column_name'],
    bucketed_by = ARRAY['column_name'],
    bucket_count = 10
) AS
SELECT
    b.mpid,
    a.zip11 as stirista_hh_id,
    a.*
FROM raw_data_20250218 a
INNER JOIN master_20241117 b
    ON a.zip11 = concat(b.zip,b.zip4,substr(b.dpc,1,2))
WHERE a.digital_flag = 'Y'


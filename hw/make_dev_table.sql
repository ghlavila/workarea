CREATE TABLE gh_dev.hw_master___RUN_DATE__
WITH ( 
external_location = 's3://gh-dev-cdc-healthwise/gv/data-proc/hw/__RUN_DATE__/',
format = 'Parquet', parquet_compression = 'SNAPPY'
)
AS SELECT * from gh_data.hw_master___RUN_DATE__

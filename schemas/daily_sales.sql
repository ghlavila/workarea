CREATE TABLE daily_sales 
(
sale_date date, 
product_category string, 
sales_amount double
)
PARTITIONED BY (month(sale_date))
TBLPROPERTIES ('table_type' = 'iceberg') 
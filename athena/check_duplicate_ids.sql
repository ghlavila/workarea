-- Check for duplicate IDs in a table using AWS Athena
-- Replace 'your_table_name' and 'id_column' with your actual table and column names

-- Option 1: Simple count of duplicates
-- This shows how many rows have duplicate IDs
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT id_column) as unique_ids,
    COUNT(*) - COUNT(DISTINCT id_column) as duplicate_count
FROM your_table_name;

-- Option 2: Show which IDs are duplicated and how many times
-- This shows the actual duplicate ID values and their counts
SELECT 
    id_column,
    COUNT(*) as occurrence_count
FROM your_table_name
GROUP BY id_column
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

-- Option 3: Show all rows that have duplicate IDs
-- This shows the complete records for rows with duplicate IDs
WITH duplicates AS (
    SELECT id_column
    FROM your_table_name
    GROUP BY id_column
    HAVING COUNT(*) > 1
)
SELECT t.*
FROM your_table_name t
INNER JOIN duplicates d ON t.id_column = d.id_column
ORDER BY t.id_column;

-- Option 4: Check for duplicates with additional context
-- This adds row numbers to help identify which records are duplicates
SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY id_column ORDER BY id_column) as row_num,
    COUNT(*) OVER (PARTITION BY id_column) as total_occurrences
FROM your_table_name
WHERE id_column IN (
    SELECT id_column
    FROM your_table_name
    GROUP BY id_column
    HAVING COUNT(*) > 1
)
ORDER BY id_column, row_num;

-- Option 5: Find duplicates based on multiple columns
-- Use this if you want to check for duplicates across multiple columns
SELECT 
    id_column,
    other_column,
    COUNT(*) as occurrence_count
FROM your_table_name
GROUP BY id_column, other_column
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

-- Option 6: Quick boolean check - returns TRUE if duplicates exist
SELECT 
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT id_column) THEN 'No duplicates found'
        ELSE 'Duplicates exist'
    END as duplicate_status
FROM your_table_name;

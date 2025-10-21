-- Dedupe on zip11 while preserving all unique segment-ids as a superset
-- This query handles comma-separated segment lists and creates a unified list per zip11

-- Method 1: Using ARRAY functions (recommended for Athena)
WITH exploded_segments AS (
    -- Split comma-separated segments into individual rows
    SELECT 
        zip11,
        TRIM(segment_id) as segment_id
    FROM stirista_direct_taxonomy_raw_20250701
    CROSS JOIN UNNEST(SPLIT(segments, ',')) AS t(segment_id)
    WHERE TRIM(segment_id) != '' -- Remove empty segments
),
unique_segments AS (
    -- Get unique segment_ids per zip11
    SELECT 
        zip11,
        segment_id
    FROM exploded_segments
    GROUP BY zip11, segment_id
)
-- Recombine into comma-separated list per zip11
SELECT 
    zip11,
    ARRAY_JOIN(ARRAY_AGG(segment_id ORDER BY segment_id), ',') as segments
FROM unique_segments
GROUP BY zip11
ORDER BY zip11;

-- Method 2: Alternative approach using STRING functions
WITH segment_explosion AS (
    SELECT DISTINCT
        zip11,
        TRIM(segment_value) as segment_id
    FROM your_table_name
    CROSS JOIN UNNEST(SPLIT(segments, ',')) AS t(segment_value)
    WHERE TRIM(segment_value) != ''
)
SELECT 
    zip11,
    ARRAY_JOIN(ARRAY_AGG(DISTINCT segment_id ORDER BY segment_id), ',') as segments
FROM segment_explosion
GROUP BY zip11
ORDER BY zip11;

-- Method 3: If you want to see the original vs deduplicated comparison
WITH original_data AS (
    SELECT 
        zip11,
        segments,
        ROW_NUMBER() OVER (PARTITION BY zip11 ORDER BY zip11) as row_num
    FROM your_table_name
),
exploded_segments AS (
    SELECT 
        zip11,
        TRIM(segment_id) as segment_id
    FROM your_table_name
    CROSS JOIN UNNEST(SPLIT(segments, ',')) AS t(segment_id)
    WHERE TRIM(segment_id) != ''
),
deduplicated AS (
    SELECT 
        zip11,
        ARRAY_JOIN(ARRAY_AGG(DISTINCT segment_id ORDER BY segment_id), ',') as new_segments
    FROM exploded_segments
    GROUP BY zip11
)
SELECT 
    d.zip11,
    STRING_AGG(o.segments, ' | ') as original_segments,
    d.new_segments as deduplicated_segments,
    COUNT(o.zip11) as original_row_count
FROM deduplicated d
LEFT JOIN original_data o ON d.zip11 = o.zip11
GROUP BY d.zip11, d.new_segments
ORDER BY d.zip11;

-- Method 4: Simple version if segments are already clean
SELECT 
    zip11,
    ARRAY_JOIN(
        ARRAY_AGG(
            DISTINCT TRIM(segment_id) 
            ORDER BY TRIM(segment_id)
        ), 
        ','
    ) as segments
FROM your_table_name
CROSS JOIN UNNEST(SPLIT(segments, ',')) AS t(segment_id)
WHERE TRIM(segment_id) != ''
GROUP BY zip11
ORDER BY zip11;

SELECT
    trigger_date,
    zip11,
    array_join(
        array_distinct(
            flatten(
                array_agg(split(segments, ','))
            )
        ),
        ','
    ) as segments
FROM table_name
GROUP BY trigger_date, zip11

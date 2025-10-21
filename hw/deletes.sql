DELETE FROM "database_name"."table_c"
WHERE mpid IN (
    SELECT b.mpid
    FROM "database_name"."table_a" a
    JOIN "database_name"."table_b" b ON a.pid = b.pid
)

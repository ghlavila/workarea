

-- one time alter to set vacuum defaults (7 days) 
ALTER TABLE gh_data.geo_master_20250504 SET TBLPROPERTIES (
  'vacuum_max_snapshot_age_seconds'='604800',   
  'vacuum_min_snapshots_to_keep'='5',
  'vacuum_max_metadata_files_to_keep'='100'
);

-- optimize table
OPTIMIZE gh_data.geo_master_20250504 REWRITE DATA USING BIN_PACK;

-- vacuum table
VACUUM gh_data.geo_master_20250504;



-- to set the current snapshot id
-- This updates the current pointer; newer snapshots remain in metadata until retention/VACUUM removes them.

-- List snapshots to get id's 
SELECT snapshot_id, made_current_at, parent_id, is_current_ancestor
FROM "gh_data"."geo_master_20250504$history"
ORDER BY made_current_at DESC;
--OR
SELECT snapshot_id, committed_at, operation
FROM "gh_data"."geo_master_20250504$snapshots"
ORDER BY committed_at DESC;

-- pick a snapshot id
-- make a snapshot id the current one
ALTER TABLE gh_data.geo_master_20250504
SET TBLPROPERTIES ('current-snapshot-id'='1234567890123');

-- verify the current snapshot
SELECT name, snapshot_id
FROM "gh_data"."geo_master_20250504$refs"
WHERE name = 'main';
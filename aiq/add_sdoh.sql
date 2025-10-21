CREATE TABLE gh_data.aiqhh_master_sdoh_20250305
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    external_location = 's3://gh-prod-cdc-aiq/gv/data-proc/aiq/20250305/athena/aiqhh_master_sdoh'
    --bucketed_by = ARRAY['mpid'],
    --bucket_count = 64
)
AS 
SELECT 
  m.*,
  s.sdoh_access_caretaker, 
  s.sdoh_access_med_facility, 
  s.sdoh_access_med_supplies, 
  s.sdoh_health_actions_comfort, 
  s.sdoh_health_literacy, 
  s.sdoh_resource_aware, 
  s.sdoh_self_advocate, 
  s.sdoh_total_health_actions
FROM 
  gh_data.aiqhh_master_20241105 m
LEFT JOIN 
  gh_build.aiq_hh_skinny_20250227 s
ON 
  CONCAT(m.aiq_hhid, m.aiq_indid) = CONCAT(s.aiq_hhid, s.aiq_indid)

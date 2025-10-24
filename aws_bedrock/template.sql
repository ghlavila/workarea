with aiq as ( select
    mpid,
    zip
    from gh_data.aiq_20250807_with_mpid
),
companies_groups as (
    select 'Allstate Vehicle & Prop Ins Co' as company, 'ALLSTATE INS GRP' as org_group union all
    select 'Great Northern Ins Co', 'Chubb Ltd Grp' union all
    select 'American Strategic Ins Corp', 'PROGRESSIVE GRP' union all
    select 'Auto-Owners Ins Co', 'AUTO OWNERS GRP' union all
    select 'Erie Ins Co', 'ERIE INS GRP' union all
    select 'American Family Ins Co', 'AMERICAN FAMILY INS GRP' union all
    select 'Shelter Mutual Ins Co', 'SHELTER INS GRP' union all
),
fi as (
SELECT
      d.zipcode,
      -- Allstate Vehicle & Prop Ins Co
      MAX(CASE WHEN d.company = 'Allstate Vehicle & Prop Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS allstate_vehicle_prop_ins_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'Allstate Vehicle & Prop Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS allstate_vehicle_prop_ins_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'Allstate Vehicle & Prop Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS allstate_vehicle_prop_ins_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'Allstate Vehicle & Prop Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS allstate_vehicle_prop_ins_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'Allstate Vehicle & Prop Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS allstate_vehicle_prop_ins_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'Allstate Vehicle & Prop Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS allstate_vehicle_prop_ins_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'Allstate Vehicle & Prop Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS allstate_vehicle_prop_ins_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'Allstate Vehicle & Prop Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS allstate_vehicle_prop_ins_co_age30_cov750k,
      -- Great Northern Ins Co
      MAX(CASE WHEN d.company = 'Great Northern Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS great_northern_ins_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'Great Northern Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS great_northern_ins_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'Great Northern Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS great_northern_ins_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'Great Northern Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS great_northern_ins_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'Great Northern Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS great_northern_ins_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'Great Northern Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS great_northern_ins_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'Great Northern Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS great_northern_ins_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'Great Northern Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS great_northern_ins_co_age30_cov750k,
      -- American Strategic Ins Corp
      MAX(CASE WHEN d.company = 'American Strategic Ins Corp' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS american_strategic_ins_corp_age0_cov200k,
      MAX(CASE WHEN d.company = 'American Strategic Ins Corp' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS american_strategic_ins_corp_age0_cov350k,
      MAX(CASE WHEN d.company = 'American Strategic Ins Corp' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS american_strategic_ins_corp_age0_cov500k,
      MAX(CASE WHEN d.company = 'American Strategic Ins Corp' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS american_strategic_ins_corp_age0_cov750k,
      MAX(CASE WHEN d.company = 'American Strategic Ins Corp' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS american_strategic_ins_corp_age30_cov200k,
      MAX(CASE WHEN d.company = 'American Strategic Ins Corp' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS american_strategic_ins_corp_age30_cov350k,
      MAX(CASE WHEN d.company = 'American Strategic Ins Corp' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS american_strategic_ins_corp_age30_cov500k,
      MAX(CASE WHEN d.company = 'American Strategic Ins Corp' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS american_strategic_ins_corp_age30_cov750k,
  FROM gh_build.fi_home_20251010 d
  INNER JOIN companies_groups cg ON d.company = cg.company
  GROUP BY d.zipcode
),
output as (
    select mpid,
      zip,
      b.zipcode,
      -- Allstate Vehicle & Prop Ins Co
      allstate_vehicle_prop_ins_co_age0_cov200k,
      allstate_vehicle_prop_ins_co_age0_cov350k,
      allstate_vehicle_prop_ins_co_age0_cov500k,
      allstate_vehicle_prop_ins_co_age0_cov750k,
      allstate_vehicle_prop_ins_co_age30_cov200k,
      allstate_vehicle_prop_ins_co_age30_cov350k,
      allstate_vehicle_prop_ins_co_age30_cov500k,
      allstate_vehicle_prop_ins_co_age30_cov750k,
      -- Great Northern Ins Co
      great_northern_ins_co_age0_cov200k,
      great_northern_ins_co_age0_cov350k,
      great_northern_ins_co_age0_cov500k,
      great_northern_ins_co_age0_cov750k,
      great_northern_ins_co_age30_cov200k,
      great_northern_ins_co_age30_cov350k,
      great_northern_ins_co_age30_cov500k,
      great_northern_ins_co_age30_cov750k,
      -- American Strategic Ins Corp
      american_strategic_ins_corp_age0_cov200k,
      american_strategic_ins_corp_age0_cov350k,
      american_strategic_ins_corp_age0_cov500k,
      american_strategic_ins_corp_age0_cov750k,
      american_strategic_ins_corp_age30_cov200k,
      american_strategic_ins_corp_age30_cov350k,
      american_strategic_ins_corp_age30_cov500k,
      american_strategic_ins_corp_age30_cov750k
    from aiq a
    inner join fi b on (
        a.zip = b.zipcode
    )
)
select * from output
ORDER BY CAST(mpid AS INTEGER)
;

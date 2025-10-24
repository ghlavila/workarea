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
    select 'COUNTRY Mutual Ins Co', 'Country Ins & Fin Serv Grp' union all
    select 'Nationwide P&C Ins Co', 'NATIONWIDE CORP GRP' union all
    select 'Owners Ins Co', 'AUTO OWNERS GRP' union all
    select 'Safeco Ins Co of America', 'LIBERTY MUT GRP' union all
    select 'Liberty Mutual Personal Ins Co', 'LIBERTY MUT GRP' union all
    select 'MemberSelect Ins Co', 'AUTOMOBILE CLUB MI GRP' union all
    select 'Safeco Ins Co of IL', 'LIBERTY MUT GRP' union all
    select 'TravCo Ins Co', 'Travelers Grp' union all
    select 'Colorado Farm Bureau Ins Co', 'SOUTHERN FARM BUREAU CAS GRP' union all
    select 'Farmers Ins Exchange', 'FARMERS INS GRP' union all
    select 'State Farm Fire & Casualty Co', 'STATE FARM GRP'
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
      -- Auto-Owners Ins Co
      MAX(CASE WHEN d.company = 'Auto-Owners Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS auto_owners_ins_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'Auto-Owners Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS auto_owners_ins_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'Auto-Owners Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS auto_owners_ins_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'Auto-Owners Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS auto_owners_ins_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'Auto-Owners Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS auto_owners_ins_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'Auto-Owners Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS auto_owners_ins_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'Auto-Owners Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS auto_owners_ins_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'Auto-Owners Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS auto_owners_ins_co_age30_cov750k,
      -- Erie Ins Co
      MAX(CASE WHEN d.company = 'Erie Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS erie_ins_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'Erie Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS erie_ins_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'Erie Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS erie_ins_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'Erie Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS erie_ins_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'Erie Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS erie_ins_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'Erie Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS erie_ins_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'Erie Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS erie_ins_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'Erie Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS erie_ins_co_age30_cov750k,
      -- American Family Ins Co
      MAX(CASE WHEN d.company = 'American Family Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS american_family_ins_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'American Family Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS american_family_ins_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'American Family Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS american_family_ins_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'American Family Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS american_family_ins_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'American Family Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS american_family_ins_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'American Family Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS american_family_ins_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'American Family Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS american_family_ins_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'American Family Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS american_family_ins_co_age30_cov750k,
      -- Shelter Mutual Ins Co
      MAX(CASE WHEN d.company = 'Shelter Mutual Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS shelter_mutual_ins_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'Shelter Mutual Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS shelter_mutual_ins_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'Shelter Mutual Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS shelter_mutual_ins_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'Shelter Mutual Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS shelter_mutual_ins_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'Shelter Mutual Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS shelter_mutual_ins_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'Shelter Mutual Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS shelter_mutual_ins_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'Shelter Mutual Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS shelter_mutual_ins_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'Shelter Mutual Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS shelter_mutual_ins_co_age30_cov750k,
      -- COUNTRY Mutual Ins Co
      MAX(CASE WHEN d.company = 'COUNTRY Mutual Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS country_mutual_ins_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'COUNTRY Mutual Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS country_mutual_ins_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'COUNTRY Mutual Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS country_mutual_ins_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'COUNTRY Mutual Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS country_mutual_ins_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'COUNTRY Mutual Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS country_mutual_ins_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'COUNTRY Mutual Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS country_mutual_ins_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'COUNTRY Mutual Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS country_mutual_ins_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'COUNTRY Mutual Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS country_mutual_ins_co_age30_cov750k,
      -- Nationwide P&C Ins Co
      MAX(CASE WHEN d.company = 'Nationwide P&C Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS nationwide_pc_ins_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'Nationwide P&C Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS nationwide_pc_ins_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'Nationwide P&C Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS nationwide_pc_ins_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'Nationwide P&C Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS nationwide_pc_ins_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'Nationwide P&C Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS nationwide_pc_ins_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'Nationwide P&C Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS nationwide_pc_ins_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'Nationwide P&C Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS nationwide_pc_ins_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'Nationwide P&C Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS nationwide_pc_ins_co_age30_cov750k,
      -- Owners Ins Co
      MAX(CASE WHEN d.company = 'Owners Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS owners_ins_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'Owners Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS owners_ins_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'Owners Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS owners_ins_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'Owners Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS owners_ins_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'Owners Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS owners_ins_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'Owners Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS owners_ins_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'Owners Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS owners_ins_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'Owners Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS owners_ins_co_age30_cov750k,
      -- Safeco Ins Co of America
      MAX(CASE WHEN d.company = 'Safeco Ins Co of America' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS safeco_ins_co_of_america_age0_cov200k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of America' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS safeco_ins_co_of_america_age0_cov350k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of America' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS safeco_ins_co_of_america_age0_cov500k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of America' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS safeco_ins_co_of_america_age0_cov750k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of America' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS safeco_ins_co_of_america_age30_cov200k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of America' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS safeco_ins_co_of_america_age30_cov350k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of America' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS safeco_ins_co_of_america_age30_cov500k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of America' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS safeco_ins_co_of_america_age30_cov750k,
      -- Liberty Mutual Personal Ins Co
      MAX(CASE WHEN d.company = 'Liberty Mutual Personal Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS liberty_mutual_personal_ins_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'Liberty Mutual Personal Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS liberty_mutual_personal_ins_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'Liberty Mutual Personal Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS liberty_mutual_personal_ins_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'Liberty Mutual Personal Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS liberty_mutual_personal_ins_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'Liberty Mutual Personal Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS liberty_mutual_personal_ins_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'Liberty Mutual Personal Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS liberty_mutual_personal_ins_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'Liberty Mutual Personal Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS liberty_mutual_personal_ins_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'Liberty Mutual Personal Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS liberty_mutual_personal_ins_co_age30_cov750k,
      -- MemberSelect Ins Co
      MAX(CASE WHEN d.company = 'MemberSelect Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS memberselect_ins_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'MemberSelect Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS memberselect_ins_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'MemberSelect Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS memberselect_ins_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'MemberSelect Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS memberselect_ins_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'MemberSelect Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS memberselect_ins_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'MemberSelect Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS memberselect_ins_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'MemberSelect Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS memberselect_ins_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'MemberSelect Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS memberselect_ins_co_age30_cov750k,
      -- Safeco Ins Co of IL
      MAX(CASE WHEN d.company = 'Safeco Ins Co of IL' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS safeco_ins_co_of_il_age0_cov200k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of IL' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS safeco_ins_co_of_il_age0_cov350k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of IL' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS safeco_ins_co_of_il_age0_cov500k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of IL' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS safeco_ins_co_of_il_age0_cov750k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of IL' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS safeco_ins_co_of_il_age30_cov200k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of IL' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS safeco_ins_co_of_il_age30_cov350k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of IL' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS safeco_ins_co_of_il_age30_cov500k,
      MAX(CASE WHEN d.company = 'Safeco Ins Co of IL' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS safeco_ins_co_of_il_age30_cov750k,
      -- TravCo Ins Co
      MAX(CASE WHEN d.company = 'TravCo Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS travco_ins_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'TravCo Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS travco_ins_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'TravCo Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS travco_ins_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'TravCo Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS travco_ins_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'TravCo Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS travco_ins_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'TravCo Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS travco_ins_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'TravCo Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS travco_ins_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'TravCo Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS travco_ins_co_age30_cov750k,
      -- Colorado Farm Bureau Ins Co
      MAX(CASE WHEN d.company = 'Colorado Farm Bureau Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS colorado_farm_bureau_ins_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'Colorado Farm Bureau Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS colorado_farm_bureau_ins_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'Colorado Farm Bureau Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS colorado_farm_bureau_ins_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'Colorado Farm Bureau Ins Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS colorado_farm_bureau_ins_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'Colorado Farm Bureau Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS colorado_farm_bureau_ins_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'Colorado Farm Bureau Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS colorado_farm_bureau_ins_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'Colorado Farm Bureau Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS colorado_farm_bureau_ins_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'Colorado Farm Bureau Ins Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS colorado_farm_bureau_ins_co_age30_cov750k,
      -- Farmers Ins Exchange
      MAX(CASE WHEN d.company = 'Farmers Ins Exchange' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS farmers_ins_exchange_age0_cov200k,
      MAX(CASE WHEN d.company = 'Farmers Ins Exchange' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS farmers_ins_exchange_age0_cov350k,
      MAX(CASE WHEN d.company = 'Farmers Ins Exchange' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS farmers_ins_exchange_age0_cov500k,
      MAX(CASE WHEN d.company = 'Farmers Ins Exchange' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS farmers_ins_exchange_age0_cov750k,
      MAX(CASE WHEN d.company = 'Farmers Ins Exchange' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS farmers_ins_exchange_age30_cov200k,
      MAX(CASE WHEN d.company = 'Farmers Ins Exchange' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS farmers_ins_exchange_age30_cov350k,
      MAX(CASE WHEN d.company = 'Farmers Ins Exchange' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS farmers_ins_exchange_age30_cov500k,
      MAX(CASE WHEN d.company = 'Farmers Ins Exchange' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS farmers_ins_exchange_age30_cov750k,
      -- State Farm Fire & Casualty Co
      MAX(CASE WHEN d.company = 'State Farm Fire & Casualty Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS state_farm_fire_casualty_co_age0_cov200k,
      MAX(CASE WHEN d.company = 'State Farm Fire & Casualty Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS state_farm_fire_casualty_co_age0_cov350k,
      MAX(CASE WHEN d.company = 'State Farm Fire & Casualty Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS state_farm_fire_casualty_co_age0_cov500k,
      MAX(CASE WHEN d.company = 'State Farm Fire & Casualty Co' AND d.dwellingage = '0' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS state_farm_fire_casualty_co_age0_cov750k,
      MAX(CASE WHEN d.company = 'State Farm Fire & Casualty Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '200000' THEN d.cps END) AS state_farm_fire_casualty_co_age30_cov200k,
      MAX(CASE WHEN d.company = 'State Farm Fire & Casualty Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '350000' THEN d.cps END) AS state_farm_fire_casualty_co_age30_cov350k,
      MAX(CASE WHEN d.company = 'State Farm Fire & Casualty Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '500000' THEN d.cps END) AS state_farm_fire_casualty_co_age30_cov500k,
      MAX(CASE WHEN d.company = 'State Farm Fire & Casualty Co' AND d.dwellingage = '30' AND d.dwellingcoverageamount = '750000' THEN d.cps END) AS state_farm_fire_casualty_co_age30_cov750k
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
      american_strategic_ins_corp_age30_cov750k,
      -- Auto-Owners Ins Co
      auto_owners_ins_co_age0_cov200k,
      auto_owners_ins_co_age0_cov350k,
      auto_owners_ins_co_age0_cov500k,
      auto_owners_ins_co_age0_cov750k,
      auto_owners_ins_co_age30_cov200k,
      auto_owners_ins_co_age30_cov350k,
      auto_owners_ins_co_age30_cov500k,
      auto_owners_ins_co_age30_cov750k,
      -- Erie Ins Co
      erie_ins_co_age0_cov200k,
      erie_ins_co_age0_cov350k,
      erie_ins_co_age0_cov500k,
      erie_ins_co_age0_cov750k,
      erie_ins_co_age30_cov200k,
      erie_ins_co_age30_cov350k,
      erie_ins_co_age30_cov500k,
      erie_ins_co_age30_cov750k,
      -- American Family Ins Co
      american_family_ins_co_age0_cov200k,
      american_family_ins_co_age0_cov350k,
      american_family_ins_co_age0_cov500k,
      american_family_ins_co_age0_cov750k,
      american_family_ins_co_age30_cov200k,
      american_family_ins_co_age30_cov350k,
      american_family_ins_co_age30_cov500k,
      american_family_ins_co_age30_cov750k,
      -- Shelter Mutual Ins Co
      shelter_mutual_ins_co_age0_cov200k,
      shelter_mutual_ins_co_age0_cov350k,
      shelter_mutual_ins_co_age0_cov500k,
      shelter_mutual_ins_co_age0_cov750k,
      shelter_mutual_ins_co_age30_cov200k,
      shelter_mutual_ins_co_age30_cov350k,
      shelter_mutual_ins_co_age30_cov500k,
      shelter_mutual_ins_co_age30_cov750k,
      -- COUNTRY Mutual Ins Co
      country_mutual_ins_co_age0_cov200k,
      country_mutual_ins_co_age0_cov350k,
      country_mutual_ins_co_age0_cov500k,
      country_mutual_ins_co_age0_cov750k,
      country_mutual_ins_co_age30_cov200k,
      country_mutual_ins_co_age30_cov350k,
      country_mutual_ins_co_age30_cov500k,
      country_mutual_ins_co_age30_cov750k,
      -- Nationwide P&C Ins Co
      nationwide_pc_ins_co_age0_cov200k,
      nationwide_pc_ins_co_age0_cov350k,
      nationwide_pc_ins_co_age0_cov500k,
      nationwide_pc_ins_co_age0_cov750k,
      nationwide_pc_ins_co_age30_cov200k,
      nationwide_pc_ins_co_age30_cov350k,
      nationwide_pc_ins_co_age30_cov500k,
      nationwide_pc_ins_co_age30_cov750k,
      -- Owners Ins Co
      owners_ins_co_age0_cov200k,
      owners_ins_co_age0_cov350k,
      owners_ins_co_age0_cov500k,
      owners_ins_co_age0_cov750k,
      owners_ins_co_age30_cov200k,
      owners_ins_co_age30_cov350k,
      owners_ins_co_age30_cov500k,
      owners_ins_co_age30_cov750k,
      -- Safeco Ins Co of America
      safeco_ins_co_of_america_age0_cov200k,
      safeco_ins_co_of_america_age0_cov350k,
      safeco_ins_co_of_america_age0_cov500k,
      safeco_ins_co_of_america_age0_cov750k,
      safeco_ins_co_of_america_age30_cov200k,
      safeco_ins_co_of_america_age30_cov350k,
      safeco_ins_co_of_america_age30_cov500k,
      safeco_ins_co_of_america_age30_cov750k,
      -- Liberty Mutual Personal Ins Co
      liberty_mutual_personal_ins_co_age0_cov200k,
      liberty_mutual_personal_ins_co_age0_cov350k,
      liberty_mutual_personal_ins_co_age0_cov500k,
      liberty_mutual_personal_ins_co_age0_cov750k,
      liberty_mutual_personal_ins_co_age30_cov200k,
      liberty_mutual_personal_ins_co_age30_cov350k,
      liberty_mutual_personal_ins_co_age30_cov500k,
      liberty_mutual_personal_ins_co_age30_cov750k,
      -- MemberSelect Ins Co
      memberselect_ins_co_age0_cov200k,
      memberselect_ins_co_age0_cov350k,
      memberselect_ins_co_age0_cov500k,
      memberselect_ins_co_age0_cov750k,
      memberselect_ins_co_age30_cov200k,
      memberselect_ins_co_age30_cov350k,
      memberselect_ins_co_age30_cov500k,
      memberselect_ins_co_age30_cov750k,
      -- Safeco Ins Co of IL
      safeco_ins_co_of_il_age0_cov200k,
      safeco_ins_co_of_il_age0_cov350k,
      safeco_ins_co_of_il_age0_cov500k,
      safeco_ins_co_of_il_age0_cov750k,
      safeco_ins_co_of_il_age30_cov200k,
      safeco_ins_co_of_il_age30_cov350k,
      safeco_ins_co_of_il_age30_cov500k,
      safeco_ins_co_of_il_age30_cov750k,
      -- TravCo Ins Co
      travco_ins_co_age0_cov200k,
      travco_ins_co_age0_cov350k,
      travco_ins_co_age0_cov500k,
      travco_ins_co_age0_cov750k,
      travco_ins_co_age30_cov200k,
      travco_ins_co_age30_cov350k,
      travco_ins_co_age30_cov500k,
      travco_ins_co_age30_cov750k,
      -- Colorado Farm Bureau Ins Co
      colorado_farm_bureau_ins_co_age0_cov200k,
      colorado_farm_bureau_ins_co_age0_cov350k,
      colorado_farm_bureau_ins_co_age0_cov500k,
      colorado_farm_bureau_ins_co_age0_cov750k,
      colorado_farm_bureau_ins_co_age30_cov200k,
      colorado_farm_bureau_ins_co_age30_cov350k,
      colorado_farm_bureau_ins_co_age30_cov500k,
      colorado_farm_bureau_ins_co_age30_cov750k,
      -- Farmers Ins Exchange
      farmers_ins_exchange_age0_cov200k,
      farmers_ins_exchange_age0_cov350k,
      farmers_ins_exchange_age0_cov500k,
      farmers_ins_exchange_age0_cov750k,
      farmers_ins_exchange_age30_cov200k,
      farmers_ins_exchange_age30_cov350k,
      farmers_ins_exchange_age30_cov500k,
      farmers_ins_exchange_age30_cov750k,
      -- State Farm Fire & Casualty Co
      state_farm_fire_casualty_co_age0_cov200k,
      state_farm_fire_casualty_co_age0_cov350k,
      state_farm_fire_casualty_co_age0_cov500k,
      state_farm_fire_casualty_co_age0_cov750k,
      state_farm_fire_casualty_co_age30_cov200k,
      state_farm_fire_casualty_co_age30_cov350k,
      state_farm_fire_casualty_co_age30_cov500k,
      state_farm_fire_casualty_co_age30_cov750k
    from aiq a
    inner join fi b on (
        a.zip = b.zipcode
    )
)
select * from output
ORDER BY CAST(mpid AS INTEGER)
;

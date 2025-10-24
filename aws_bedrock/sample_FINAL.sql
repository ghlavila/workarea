with aiq as ( select
    mpid,
    zip,
    case 
        when aiq_gender in ('Male', 'Inferred Male') then 'Male'
        when aiq_gender in ('Female', 'Inferred Female') then 'Female'
        else aiq_gender
    end as gender,
    case aiq_marital_v2
        when 'Married Now' then 'Married'
        else 'Single'
    end as marital_status,
    case 
        when CAST(aiq_age AS INTEGER) between 25 and 34 then '25'
        when CAST(aiq_age AS INTEGER) between 35 and 44 then '35'
        when CAST(aiq_age AS INTEGER) between 45 and 54 then '45'
        when CAST(aiq_age AS INTEGER) between 55 and 64 then '55'
        when CAST(aiq_age AS INTEGER) >= 65 then '65'
        else '24'
    end as age
    from gh_data.aiq_20250807_with_mpid
),
companies_groups as (
    select 'Bristol West Preferred Ins Co' as company, 'FARMERS INS GRP' as grp union all
    select 'GEICO Ind Co', 'BERKSHIRE HATHAWAY GRP' union all
    select 'Progressive Advanced Ins Co', 'PROGRESSIVE GRP' union all
    select 'Safeway Ins Co of LA', 'SAFEWAY INS GRP' union all
    select 'Dairyland County Mutual Ins Co', 'SENTRY INS GRP' union all
    select 'Allstate Ind Co', 'ALLSTATE INS GRP' union all
    select 'Mountain Laurel Assurance Co', 'PROGRESSIVE GRP' union all
    select 'Viking Ins Co of WI', 'SENTRY INS GRP' union all
    select 'Progressive Universal Ins Co', 'PROGRESSIVE GRP' union all
    select 'Direct General Ins Co of MS', 'ALLSTATE INS GRP' union all
    select 'Progressive Direct Ins Co', 'PROGRESSIVE GRP' union all
    select 'Progressive Max Ins Co', 'PROGRESSIVE GRP' union all
    select 'Sentry Ins Co', 'SENTRY INS GRP' union all
    select 'Direct General Ins Co', 'ALLSTATE INS GRP' union all
    select 'Progressive County Mutl Ins Co', 'PROGRESSIVE GRP' union all
    select 'Dairyland Ins Co', 'SENTRY INS GRP' union all
    select 'Peak P&C Ins Corp', 'SENTRY INS GRP' union all
    select 'Permanent General Assr Corp', 'SENTRY INS GRP' union all
    select 'Progressive Select Ins Co', 'PROGRESSIVE GRP' union all
    select 'Infinity Ins Co', 'Kemper Corp Grp' union all
    select 'State Farm Fire & Casualty Co', 'STATE FARM GRP' union all
    select 'Safeway Ins Co of GA', 'SAFEWAY INS GRP' union all
    select 'Progressive Marathon Ins Co', 'PROGRESSIVE GRP' union all
    select 'Safeway Ins Co', 'SAFEWAY INS GRP' union all
    select 'Bristol West Ins Co', 'FARMERS INS GRP' union all
    select 'MGA Ins Co', 'STATE FARM GRP' union all
    select 'Progressive Premier Ins Co', 'PROGRESSIVE GRP' union all
    select 'American Access Casualty Co', 'Kemper Corp Grp' union all
    select 'Progressive Paloverde Ins Co', 'PROGRESSIVE GRP' union all
    select 'United Financial Casualty Co', 'PROGRESSIVE GRP' union all
    select 'Safeway Ins Co of AL Inc', 'SAFEWAY INS GRP'
),
fi as ( 
SELECT
      d.zip,
      d.age,
      d.gender,
      d.marital_status,
      MAX(CASE WHEN d.company = 'Bristol West Preferred Ins Co' THEN d.cps END) AS bristol_west_preferred_ins_co,
      MAX(CASE WHEN d.company = 'GEICO Ind Co' THEN d.cps END) AS geico_ind_co,
      MAX(CASE WHEN d.company = 'Progressive Advanced Ins Co' THEN d.cps END) AS progressive_advanced_ins_co,
      MAX(CASE WHEN d.company = 'Safeway Ins Co of LA' THEN d.cps END) AS safeway_ins_co_of_la,
      MAX(CASE WHEN d.company = 'Dairyland County Mutual Ins Co' THEN d.cps END) AS dairyland_county_mutual_ins_co,
      MAX(CASE WHEN d.company = 'Allstate Ind Co' THEN d.cps END) AS allstate_ind_co,
      MAX(CASE WHEN d.company = 'Mountain Laurel Assurance Co' THEN d.cps END) AS mountain_laurel_assurance_co,
      MAX(CASE WHEN d.company = 'Viking Ins Co of WI' THEN d.cps END) AS viking_ins_co_of_wi,
      MAX(CASE WHEN d.company = 'Progressive Universal Ins Co' THEN d.cps END) AS progressive_universal_ins_co,
      MAX(CASE WHEN d.company = 'Direct General Ins Co of MS' THEN d.cps END) AS direct_general_ins_co_of_ms,
      MAX(CASE WHEN d.company = 'Progressive Direct Ins Co' THEN d.cps END) AS progressive_direct_ins_co,
      MAX(CASE WHEN d.company = 'Progressive Max Ins Co' THEN d.cps END) AS progressive_max_ins_co,
      MAX(CASE WHEN d.company = 'Sentry Ins Co' THEN d.cps END) AS sentry_ins_co,
      MAX(CASE WHEN d.company = 'Direct General Ins Co' THEN d.cps END) AS direct_general_ins_co,
      MAX(CASE WHEN d.company = 'Progressive County Mutl Ins Co' THEN d.cps END) AS progressive_county_mutl_ins_co,
      MAX(CASE WHEN d.company = 'Dairyland Ins Co' THEN d.cps END) AS dairyland_ins_co,
      MAX(CASE WHEN d.company = 'Peak P&C Ins Corp' THEN d.cps END) AS peak_pc_ins_corp,
      MAX(CASE WHEN d.company = 'Permanent General Assr Corp' THEN d.cps END) AS permanent_general_assr_corp,
      MAX(CASE WHEN d.company = 'Progressive Select Ins Co' THEN d.cps END) AS progressive_select_ins_co,
      MAX(CASE WHEN d.company = 'Infinity Ins Co' THEN d.cps END) AS infinity_ins_co,
      MAX(CASE WHEN d.company = 'State Farm Fire & Casualty Co' THEN d.cps END) AS state_farm_fire_casualty_co,
      MAX(CASE WHEN d.company = 'Safeway Ins Co of GA' THEN d.cps END) AS safeway_ins_co_of_ga,
      MAX(CASE WHEN d.company = 'Progressive Marathon Ins Co' THEN d.cps END) AS progressive_marathon_ins_co,
      MAX(CASE WHEN d.company = 'Safeway Ins Co' THEN d.cps END) AS safeway_ins_co,
      MAX(CASE WHEN d.company = 'Bristol West Ins Co' THEN d.cps END) AS bristol_west_ins_co,
      MAX(CASE WHEN d.company = 'MGA Ins Co' THEN d.cps END) AS mga_ins_co,
      MAX(CASE WHEN d.company = 'Progressive Premier Ins Co' THEN d.cps END) AS progressive_premier_ins_co,
      MAX(CASE WHEN d.company = 'American Access Casualty Co' THEN d.cps END) AS american_access_casualty_co,
      MAX(CASE WHEN d.company = 'Progressive Paloverde Ins Co' THEN d.cps END) AS progressive_paloverde_ins_co,
      MAX(CASE WHEN d.company = 'United Financial Casualty Co' THEN d.cps END) AS united_financial_casualty_co,
      MAX(CASE WHEN d.company = 'Safeway Ins Co of AL Inc' THEN d.cps END) AS safeway_ins_co_of_al_inc
  FROM gh_build.fi_nsauto_20250916 d
  INNER JOIN companies_groups cg ON d.company = cg.company
  GROUP BY d.zip, d.age, d.gender, d.marital_status
),
output as (
    select mpid, 
      bristol_west_preferred_ins_co,
      geico_ind_co,
      progressive_advanced_ins_co,
      safeway_ins_co_of_la,
      dairyland_county_mutual_ins_co,
      allstate_ind_co,
      mountain_laurel_assurance_co,
      viking_ins_co_of_wi,
      progressive_universal_ins_co,
      direct_general_ins_co_of_ms,
      progressive_direct_ins_co,
      progressive_max_ins_co,
      sentry_ins_co,
      direct_general_ins_co,
      progressive_county_mutl_ins_co,
      dairyland_ins_co,
      peak_pc_ins_corp,
      permanent_general_assr_corp,
      progressive_select_ins_co,
      infinity_ins_co,
      state_farm_fire_casualty_co,
      safeway_ins_co_of_ga,
      progressive_marathon_ins_co,
      safeway_ins_co,
      bristol_west_ins_co,
      mga_ins_co,
      progressive_premier_ins_co,
      american_access_casualty_co,
      progressive_paloverde_ins_co,
      united_financial_casualty_co,
      safeway_ins_co_of_al_inc
    from aiq a
    inner join fi b on (
        a.zip = b.zip 
        and a.age = b.age 
        and a.gender = b.gender 
        and a.marital_status = b.marital_status
    )
)
select * from output
ORDER BY CAST(mpid AS INTEGER)
;

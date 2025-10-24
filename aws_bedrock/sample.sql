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
    select 'Bristol West Preferred Ins Co' as company, 'FARMERS INS GRP' as org_group union all
    select 'GEICO Ind Co', 'BERKSHIRE HATHAWAY GRP' union all
    select 'Progressive Advanced Ins Co', 'PROGRESSIVE GRP' union all
),
fi as ( 
SELECT
      d.zip,
      d.age,
      d.gender,
      d.marital_status,
      MAX(CASE WHEN d.company = 'Bristol West Preferred Ins Co' THEN d.cps END) AS bristol_west_preferred_ins_co,
      MAX(CASE WHEN d.company = 'GEICO Ind Co' THEN d.cps END) AS geico_ind_co,
      MAX(CASE WHEN d.company = 'Progressive Advanced Ins Co' THEN d.cps END) AS progressive_advanced_ins_co
  FROM gh_build.fi_nsauto_20250916 d
  INNER JOIN companies_groups cg ON d.company = cg.company
  GROUP BY d.zip, d.age, d.gender, d.marital_status
),
output as (
    select mpid, 
      bristol_west_preferred_ins_co,
      geico_ind_co,
      progressive_advanced_ins_co
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

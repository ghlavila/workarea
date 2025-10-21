merge into geo_master___GEO_MASTER_DATE a using pd_master___PD_MASTER_DATE__ b
on a.mpid = b.mpid
when matched then 
update set
    dedupe_key = b.dedupe_key, 
    state = b.state,
    zip = b.zip, 
    county = b.county, 
    congress = b.congress,
    latitude = b.latitude,
    longitude = b.longitude
when not matched then 
insert 
(
    mpid, 
    dedupe_key, 
    state, 
    zip, 
    county, 
    congress, 
    latitude, 
    longitude 
)
values 
(
    b.mpid, 
    b.dedupe_key, 
    b.state, 
    b.zip, 
    b.county, 
    b.congress, 
    b.latitude, 
    b.longitude
)
;

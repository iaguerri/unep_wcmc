GIS Developer Test Irene Aguerri


## Introduction
The aim of this test is to take out the statistics of the WDPA given some conditions.

## Data
- WDPA Subste
- Base layer subset



## Methodology

### 1. Data preparation
As read in the **User Manual for the World Database on Protected Areas and world database on other effective area-based conservation measures: 1.6** there are some Known issues that should be taken in account:
  1. Status field:
   "Users might want to decide to include legally-designated sites only in their
analyses. In that case all sites where STATUS = ‘Proposed’, ‘Established’, and ‘Not Reported’ should be removed"

``` sql
SELECT * FROM wdpa_wdoecm_subset where status in ('Proposed','Established','Not Reported')```



query sacar geometrias buenas
``` sql
create table wdpa_poly_v2 as
with protected_areas as (
 select wdpaid, wdpa_pid, pa_def, name, orig_name, desig, desig_eng, desig_type, int_crit, marine, 
	rep_m_area, gis_m_area,rep_area, gis_area, status, status_yr, parent_iso3, iso3,
  case when st_geometrytype(shape) = 'ST_MultiPoint' then st_buffer(shape::geography, sqrt(rep_area::numeric * 1000000 / pi()))::geometry
  else shape::geometry end as geom
 from public.wdpa
)
select wdpaid, wdpa_pid, pa_def, name, orig_name, desig, desig_eng, desig_type, int_crit, marine, 
	rep_m_area, gis_m_area, rep_area, gis_area, status, status_yr, parent_iso3, iso3, st_union(geom) as geom
from protected_areas
GROUP BY wdpaid, wdpa_pid, pa_def, name, orig_name, desig, desig_eng, desig_type, int_crit, marine, 
	rep_m_area, gis_m_area, rep_area, gis_area, status, status_yr, parent_iso3, iso3

CREATE INDEX idx_geom_wdpa_poly_v2 ON wdpa_poly_v2 USING GIST(geom)
```





Sacar por ISO3CD el porcentaje de cobertura para cada PA_DEF que intersectan con el base layer
``` sql
create table pa_def_union AS
with protected_zones_per_adm1nm as (
 select b.iso3cd, b.adm1nm, b.geom, p.pa_def, st_union(p.geom) as p_geom --union de geometrias de todas las areas protegidas--
 from wdpa_poly_v2 p, base_layer_subset b
   where st_intersects(p.geom, b.geom)
 group by b.iso3cd, b.geom,b.adm1nm, p.pa_def
),
intersect_zones_per_adm1nm as(
select iso3cd, adm1nm, pa_def, St_area(geom) as area_adm1nm, st_area(st_intersection(p_geom, geom)) as area_pa_def_admn1
	
	from protected_zones_per_adm1nm
)
Select iso3cd,pa_def,100* sum(area_pa_def_admn1)/sum(area_adm1nm) as percentage_coverage --ese es el porcentaje de cobertura que piden-- 
from intersect_zones_per_adm1nm
group by iso3cd, pa_def
```





ISO3 mismatch
``` sql
DROP TABLE IF EXISTS iso3mismatch;
CREATE TABLE iso3mismatch as
with fix_iso3 as(
SELECT w.iso3 as reported_iso3 , b.iso3cd as expected_iso3, ST_Intersection(w.geom, b.geom) as geom
FROM wdpa_poly_v2 w, base_layer_subset b 
where ST_intersects(w.geom, b.geom))
Select * from fix_iso3 where reported_iso3 <> expected_iso3
```

``` sql
CREATE INDEX idx_geom_iso3mismatch ON iso3mismatch USING GIST(geom);
```
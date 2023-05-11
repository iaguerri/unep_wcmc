--1. NATIONAL COVERAGE STATISTICS
--Query to know if status is not reported
SELECT * FROM wdpa_wdoecm_subset WHERE status in ('Proposed','Established','Not Reported');

--Query of records that are rep_area<>0
CREATE TABLE wdpa AS(
	SELECT * FROM wdpa_wdoecm_subset WHERE rep_area <> 0);

--INDEX FOR TABLE--
CREATE INDEX idx_geom_wdpa USING GIST(shape)

--auxiliar table to know the number of records that are rep_area=0
CREATE TABLE excluded_ones AS(
SELECT t.name,t.pa_def,t.iso3,t.desig, t.desig_eng, t.status FROM public.wdpa_wdoecm_subset as t
WHERE rep_area = 0)

--INDEX FOR TABLE--
CREATE INDEX idx_geom_wdpa_wdoecm_subset ON public.wdpa_wdoecm_subset USING GIST (shape);




--Query to create the table with the wdpa data and the points converted to buffer
CREATE TABLE wdpa_poly_v2 as
WITH protected_areas as (
 SELECT wdpaid, wdpa_pid, pa_def, name, orig_name, desig, desig_eng, desig_type, int_crit, marine, 
	rep_m_area, gis_m_area,rep_area, gis_area, status, status_yr, parent_iso3, iso3,
  CASE WHEN ST_Geometrytype(shape) = 'ST_MultiPoint' THEN ST_Buffer(shape::geography, sqrt(rep_area::numeric * 1000000 / pi()))::geometry
  ELSE shape::geometry END as geom
 FROM public.wdpa
)
SELECT wdpaid, wdpa_pid, pa_def, name, orig_name, desig, desig_eng, desig_type, int_crit, marine, 
	rep_m_area, gis_m_area, rep_area, gis_area, status, status_yr, parent_iso3, iso3, st_union(geom) as geom
FROM protected_areas
GROUP BY wdpaid, wdpa_pid, pa_def, name, orig_name, desig, desig_eng, desig_type, int_crit, marine, 
	rep_m_area, gis_m_area, rep_area, gis_area, status, status_yr, parent_iso3, iso3

-- GEOM index for wdpa_poly_v2
CREATE INDEX idx_geom_wdpa_poly_v2 ON wdpa_poly_v2 USING GIST(geom);




--Query to get the percentage coverage of each PA_DEF in each country that intersects with the base layer
CREATE TABLE pa_def_iso3 as
WITH protected_zones_per_adm1nm as (
SELECT b.iso3cd, b.adm1nm, b.geom, p.pa_def, ST_Union(p.geom) as p_geom
 FROM wdpa_poly_v2 p, base_layer_subset b
   WHERE ST_Intersects(p.geom, b.geom)
 GROUP BY b.iso3cd, b.geom,b.adm1nm, p.pa_def
),
intersect_zones_per_adm1nm as(
SELECT iso3cd, adm1nm, pa_def, St_area(geom) as area_adm1nm, st_area(ST_Intersection(p_geom, geom)) as area_pa_def_admn1
	
	FROM protected_zones_per_adm1nm
)
SELECT iso3cd, pa_def, 100* sum(area_pa_def_admn1)/sum(area_adm1nm) as percentage_coverage
FROM intersect_zones_per_adm1nm
GROUP BY iso3cd, pa_def

-- GEOM index for pa_def_iso3
CREATE INDEX idx_geom_pa_def_iso3 ON pa_def_iso3 USING GIST(geom);




--2. ISO3 mismatch
CREATE TABLE iso3mismatch as
with fix_iso3 as(
    SELECT w.iso3 as reported_iso3 , b.iso3cd as expected_iso3, ST_Intersection(w.geom, b.geom) as geom
    FROM pa_def_iso3 w, base_layer_subset b 
    WHERE ST_Intersects(w.geom, b.geom))
Select * from fix_iso3 where reported_iso3 <> expected_iso3

CREATE INDEX idx_geom_iso3mismatch ON iso3mismatch USING GIST(geom);



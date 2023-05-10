--Query to get the GeometryTypes in PostGIS



select name,rep_area, pa_def, marine,shape from public.wdpa

CREATE INDEX idx_geom_wdpa ON public.wdpa USING GIST (shape);


--Crear tabla auxiliar--
create table protected_areas_aux as
with protected_areas as (
 select
  case when st_geometrytype(shape) = 'ST_MultiPoint' then st_buffer(shape::geography, sqrt(rep_area::numeric * 1000000 / pi()))
  else shape end as geom
 from public.wdpa
 where pa_def =  '1'
)
select st_union(geom::geometry) as geom
from protected_areas
CREATE INDEX idx_geom_protected_areas_aux ON public.protected_areas_aux USING GIST (geom);




-- Crear tabla auxiliar 2 con id, wpdai, name, pa_def, desig, desig_eng, desig_type, marine, iso3, parent_iso3, geom
DROP TABLE IF EXISTS protected_areas_aux2;
create table protected_areas_aux2 as
select id,wdpaid,name, pa_def,desig,desig_eng, desig_type, marine, iso3, parent_iso3,
 case when st_geometrytype(geom) = 'ST_MultiPoint' then st_buffer(geom::geography, sqrt(rep_area::numeric * 1000000 / pi()))::geometry
 else geom::geometry end as geom
from public.wdpa;

CREATE INDEX idx_geom_protected_areas_aux2 ON public.protected_areas_aux2 USING GIST (geom);
-- arriba hecho 




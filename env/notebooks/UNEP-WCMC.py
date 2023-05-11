#!/usr/bin/env python
# coding: utf-8

# In[42]:


import geopandas as gpd
import pandas as pd
from research.connections.db_client import DBClient
pd.set_option('display.max_columns', None)


# In[43]:


db_client = DBClient()


# In[44]:


sql_query = "SELECT * FROM public.wdpa_wdoecm_subset"


# In[45]:


wdpa_subset = db_client.read_sql(sql_query, geom_col='shape')


# In[46]:


wdpa_subset.head()


# # **1. AREA STATISTICS** 
# - Exclude proposed areas

# In[6]:


wdpa_subset.status.value_counts()


# There are no WPDA `proposed` areas, so every value should be taking in account
# 

# The dataset has points and polygons. We should check this and transform the points into polygons.

# In[7]:


query= """select distinct st_geometrytype(shape)
from public.wdpa_wdoecm_subset;"""


# In[8]:


geom_types = db_client.read_sql(query)


# In[9]:


geom_types


# In[ ]:





# - Get only REP_AREA <> 0

# As the ```WDPA_WDOECM_Manual```indicates on **5.5.2 Known issues Point Data** says 
# 
# >"If the area of a point feature has not been reported, it may be best to exclude it. To do this, users should remove points where the
# ```REP_AREA``` is zero. The remaining points can be buffered by calculating the radius of a circle
# proportional to the reported area of the site using GIS tools.
# 

# In[49]:


rep_area_0 = """ SELECT t.name,t.rep_area,iso3,st_geometrytype(t.shape) FROM public.wdpa_wdoecm_subset as t
WHERE rep_area = 0
ORDER BY id ASC"""


# In[50]:


excluded_ones = db_client.read_sql(rep_area_0)
excluded_ones


# ## Load Base Layer

# In[55]:


base_layer = gpd.read_file('../data/base_layer_subset/base_layer_subset.shp')


# In[56]:


base_layer.columns = base_layer.columns.str.lower()


# In[58]:


base_layer.to_postgis('base_layer_subset',con=db_client.engine)


# In[59]:


query_base = "SELECT * FROM public.base_layer_subset"
base_layer = db_client.read_sql(query_base, geom_col='geometry')


# In[60]:


base_layer.head()


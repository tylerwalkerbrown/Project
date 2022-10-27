#!/usr/bin/env python
# coding: utf-8

# In[27]:


import os
import pandas as pd
import matplotlib as plt
import requests
from geopy.geocoders import Nominatim
from geopy import ArcGIS
from ipyleaflet import Map,  MeasureControl
import ipywidgets
import geopandas
from geopy import ArcGIS
import matplotlib.pyplot
from pandas_profiling import ProfileReport
from geopy.geocoders import Nominatim
from geopy import distance
from math import sin, cos, sqrt, atan2
from sklearn.neighbors import DistanceMetric
from math import radians
import pandas as pd
import numpy as np
from math import radians
import pandas as pd
import numpy as np
import haversine as hs
import folium 


# In[2]:


geolocator = Nominatim()
#Assigning Arc to ArcGIS object
#dir(geopy)
Arc = ArcGIS()


# In[28]:


#conda install -c conda-forge pyogrio
os.chdir('Desktop/mojo')


# In[29]:


#Reading in the customers
df = pd.read_csv('customers.csv')


# In[8]:


#Point to the addresses witin the frame 
df["Coordinates"] = df.billaddress.apply(Arc.geocode)


# In[11]:


#Creating seperate values for lat and long
df['latitude'] = df['Coordinates'].apply(lambda x: x.latitude)
df['longitude'] = df['Coordinates'].apply(lambda y: y.longitude)


# In[122]:


#Saving the file to a csv so you dont have to re run Arc
df.to_csv('spatial_info.csv', index = False)


# In[5]:


#Reading the file back into python that you just saved to a csv
df = pd.read_csv('spatial_info.csv')
df1 = pd.read_csv('spatial_info.csv')


# In[66]:


#Median bill amount = 93
df.describe()


# In[7]:


#Plitting the address to get the name of the town and state 
split_1 = df.billaddress.str.split("'", expand = True)[1]
split_2 = split_1.str.split('0', expand = True)[0]
df['town'] = split_2


# In[49]:


#Saving the file to a csv so you dont have to re run Arc
df.to_csv('geo_spatial.csv', index = False)


# In[56]:


#Importing the new data set so you dont have to load the arc.geocode
df = pd.read_csv('geo_spatial.csv')


# In[57]:


#Choosing the columns needed to calculate the distances 
distance = df[['accountnum', 'long_lat','latitude', 'longitude']]


# In[58]:


#Converting each of the lat long points to radians
distance['lat'] = np.radians(distance['latitude'])
distance['lon'] = np.radians(distance['longitude'])


# In[59]:


#Assigning DistanceMetric.get_metric('haversine') to dist to use to calculate the distances 
dist = DistanceMetric.get_metric('haversine')


# In[64]:


#Dataframe using pairwise on lat and long to get distances
distance_matrix = pd.DataFrame(dist.pairwise(distance[['lat','lon']].to_numpy())*6373*1000/1609.34,  columns=distance.accountnum, index=distance.accountnum)


# In[67]:


#Putting the NA as zeros so the min distance doesnt return 0 
distance_matrix.replace(to_replace = 0, value = pd.NA, inplace=True)


# In[68]:


distance_matrix.to_csv('distances.csv', index = False)


# In[102]:


in_radius = pd.DataFrame(abs(distance_matrix[distance_matrix < 12].isna().sum()  - len(distance_matrix)))


# In[139]:


#Hardcoding the average spray by the count of the homes in the 12 mile radius 
in_radius['revenue_in_12'] = in_radius * 93


# In[143]:


in_radius.describe()


# In[150]:


#Binning the revenues in 12 miles long drop to great 
in_radius['category']=pd.qcut(in_radius['revenue_in_12'],
        q=[0, .2, .4, .6, .8, 1],
        labels=['Drop', 'Low', 'Average', 'Above Average', 'Great'])


# In[157]:


#merging the ones in radius of 12 miles 
export = in_radius.merge(df, on= 'accountnum')


# In[158]:


#Exporting the csv
export.to_csv('revenue_cat.csv', index = False)


# In[159]:


export.info()

<class 'pandas.core.frame.DataFrame'>
Int64Index: 463 entries, 0 to 462
Data columns (total 22 columns):
 #   Column         Non-Null Count  Dtype   
---  ------         --------------  -----   
 0   accountnum     463 non-null    int64   
 1   0              463 non-null    int64   
 2   revenue_in_12  463 non-null    int64   
 3   category       463 non-null    category
 4   branchname     463 non-null    object  
 5   BillName       463 non-null    object  
 6   billaddress    463 non-null    object  
 7   emailaddress   459 non-null    object  
 8   routename      443 non-null    object  
 9   saledate       463 non-null    object  
 10  servicedate    463 non-null    object  
 11  firstdate      463 non-null    object  
 12  lastservice    463 non-null    object  
 13  programid      463 non-null    int64   
 14  programtypeid  463 non-null    int64   
 15  programname    463 non-null    object  
 16  billamount     463 non-null    int64   
 17  Coordinates    463 non-null    object  
 18  latitude       463 non-null    float64 
 19  longitude      463 non-null    float64 
 20  long_lat       463 non-null    object  
 21  town           463 non-null    object  
dtypes: category(1), float64(2), int64(6), object(13)
memory usage: 80.2+ KB
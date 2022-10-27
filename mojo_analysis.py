#!/usr/bin/env python
# coding: utf-8

# In[ ]:





# # Mosquito Joe Reporting 

# Project will cover the following: ---Time series analysis --- Plot showing financial advances with set backs --- Projected revenue ---Summary of data year over year and overall --- Overall financial standings --- Highest earning towns that the company covers

# Table below was created in mySQL and was used to reformat the dates as actual date types rather than text. Utilized the substring command in SQL that splits up the columns on placement. After that I had to use TRIM to get rid of an slashes left in the dates for concating. I then CONCAT in the b subquery and tranform to a datetime using CAST in c. I then close off the subquery and leave it room for possible expansion. 

# In[ ]:


"""--- Re formatting the dates
create table all_sprays as(
WITH seven_figures as (
select  accountnum, sitename,siteaddress,  itemnum, 
itemdescription as chemical, 
materialquantity,usagepermixuom, useunit, eventname, employee, priceperunit, totalcost, targetname, temperature, windspeed
 ,substring(completeddate,1,2) as month1, 
substring(completeddate,3,2) as Days1,
substring(completeddate,5,3) as year1,
length(completeddate) as len,
completeddate
from mojo_sprays)
, a as (
select *,trim('/' from month1) as month ,
trim('/' from year1) as year,
trim('/' from Days1) as day
from seven_figures
)
,b as (
select *,concat(20,year,'/', month, '/', day) as completeddat
from a
)
,c as (
select *,cast(completeddat as datetime) as date
from b
)
select * 
from c"""


# This table is used to transform the resprays into negative revenue. FOr this I used a case when statement that properly assigns respray as a negative for analysis. I then multiplied the bill amount for each customers spray. Some of the data was false so I got rid of any bill amounts that were not over 1 to get rid of 0's that were repeat with accurate data. 

# In[ ]:


"""with a as 
(select accountnum as account, date,siteaddress,eventname
from all_sprays)
,b as (
select account,Billname, date,billamount,eventname,siteaddress from a 
join customer_info on a.account = customer_info.accountnum
group by accountnum, date, billamount,eventname,siteaddress,Billname)
,c as (
select * , 
case when eventname = 'Re-Spray' then -1
else 1  end as respray          
from b
where billamount > 1
)
,d as(
select account,siteaddress , date,eventname, (respray * billamount) as billamount,Billname
from c
order by date)
select account,siteaddress, date,eventname,billamount,Billname
from d """


# In[21]:


import os
import matplotlib as plt
from pandas_profiling import ProfileReport
import matplotlib.pyplot as plt
get_ipython().run_line_magic('matplotlib', 'inline')
import pandas as pd
from matplotlib.pylab import rcParams
from datetime import datetime
import datetime
from datetime import date
from datetime import *
import numpy as np


# # Mosquito Joe Reporting 

# Project will cover the following:
# ---Time series analysis 
#     --- Plot showing financial advances with set backs
#     --- Projected revenue 
#     ---Summary of data year over year and overall
# --- Overall financial standings 
# --- Highest earning towns that the company covers

# Changing the current directory to pull the csv.

# In[2]:


os.chdir('Desktop/mojo')


# In[3]:


df = pd.read_csv('mojo_revenue.csv')
latitude_long = pd.read_csv('spatial_info.csv')


# In[4]:


#Looking at the top five entries into the data 
df.head()#.to_clipboard()


# In[5]:


# Seeing how the tail compares to the head 
df.tail().to_clipboard()


# In[6]:


#Data types were working with 
#Notice we do not have any nulls in the data as we got rid of them in sql
df.info()


# In[7]:


#Data takes on a (3729, 6) shape
df.shape


# In[8]:


#Figuring out the sum amount of revenue over the years
sum(df.billamount)


# In[9]:


#Average bill amount is $99 company wide 
# Notice a very concerning -183.00 that may be inaccurate 
#Mean $5 lower than the median 
df.describe()


# In[10]:


#Splitting the columns to get the zip code to see what is the highest paid town
df['Zip'] = df.siteaddress.str.split('VT | NH | Vermont', expand = True)[1]


# In[11]:


#Looking at each town in pandas profiling
#profile = ProfileReport(df, title = 'Mojo Profiling')
profile


# In[12]:


#First entry in the dataset had an out of range 
df["datetime"] = pd.to_datetime(df.date, errors = 'coerce')
#Dropping the na values that were created in the datetime column 
#1st entry dropped showed 0020-02...
df = df.dropna()


# In[13]:


#Indexing the dataset
Indexed = df.set_index(['datetime'])


# In[14]:


#Creating a subset for the time series analysis 
billamount = Indexed[['billamount']]


# In[278]:


# Creating an input variable for desired range of dates 
#2020-1-15
start_date = input('Put start date in this format YYYY-MM-DD:')
end_date = input('Put end date in this format YYYY-MM-DD:')


# In[279]:


#Creating a filter on the dataframe from the inputs above
mask = (df['datetime'] > start_date) & (df['datetime'] <= end_date)
selected_range = df.loc[mask]


# In[280]:


#indexing the selected ranges 
selected_range_indexed = selected_range.set_index(['datetime'])


# In[281]:


#Subsetting the selected ranges cumulative summary 
selected_range_indexed = selected_range_indexed[['billamount']].cumsum()


# In[282]:


#Changing the Figure size
rcParams['figure.figsize'] = 16,6


# In[283]:


#Creating a cumulative subset to put into matplotlib
cumulative_revenue = Indexed.billamount.cumsum()


# In[284]:


#Plotting the cumulative revenue of the whole business 
plt.ylabel('Revenue')
plt.xlabel('Days')
plt.title('Overall Cumulative Revenue')
plt.plot(selected_range_indexed)


# ![image-2.png](attachment:image-2.png)

# ![image.png](attachment:image.png)

# ![image.png](attachment:image.png)

# ![image.png](attachment:image.png)

# In[17]:



#Storing the orgininal ddataframe 
Index_2=Indexed


# In[19]:


from datetime import *


# In[23]:


Indexed.date = pd.to_datetime(Indexed.date)


# In[25]:


#Creating the current date time and converting the date column to a datetime 
Indexed['today'] = datetime.datetime.now()


# In[26]:


#Calculating the difference between current date and spray to get the difference 
Indexed['Difference'] = Indexed['today'].sub(Indexed['date'], axis=0)


# In[ ]:





# In[455]:


#Subsetting the two columns I am interested in being accountnum and days 
difference = Indexed[['account', 'Difference']]


# In[472]:


#Creating a difference string to split and extract the days
difference['days'] = difference['Difference'].astype(str)
#Splitting the string we just made to get the index 0 = days
difference['days']= difference.days.str.split(' ', expand = True)[0]


# In[480]:


#Transforming the days to a float to use math operators on 
difference['days'] = difference.days.astype(float)


# In[489]:


adifference.loc[difference.days > 250]


# In[1]:


churned_list = difference.groupby('account').min('days')


# In[524]:


#Filtering out the customers that hae not used service for over 3 months
#Must be run at end of season to take not of the customer that have churned
churned_list[churned_list['days']> 100]


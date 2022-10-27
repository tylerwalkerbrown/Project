--- Re formatting the dates
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
from c



---Table used for customer info merge showing revenue per customer 
create table revenue as(
with a as 
(select 
case when eventname = 'Synthetic Barrier Spray' then 12    
when eventname = 'All-Natural Barrier Spray' or eventname = 'Botanical Barrier 3 Week' then 8              
else -1 end as number_of_sprays, accountnum as account, date,eventname    
from all_sprays             
group by accountnum,number_of_sprays ,
date,
eventname)             
, b as (             
select billamount,accountnum , number_of_sprays,
(number_of_sprays *billamount) as Revenue,
eventname, date             
from a    
right join customer_info on            
customer_info.accountnum =  a.account)
, c as (                        
select billamount, number_of_sprays,              
   eventname,accountnum ,count(date) ,AVG(Revenue) as Revenue , max(date)        
from b               
 GROUP By billamount, number_of_sprays,Revenue,  eventname,accountnum) 
 select accountnum, sum(Revenue) as revenue
 from c
 group by accountnum)
 
select sum(totalcost) from mojo_sprays


--- Splitting the data into three seperate tables
create table 2020_sprays as (
with tab as(
select * 
from all_sprays
where date between '2020-01-01' and '2020-12-01')
select * from tab
)

----Extracting the zip code from customers to get zip code usage break down.
  with a as  (select  *,reverse(siteaddress) as address
    from grouped_by_customer)
	,b as (
   select *,substring(address,1,6) as address1
   from a)
   ,c as (select *,reverse(address1) as zip
   from b)
   select zip,sum(Amount_used),final_measure,chemical_name,sum(Quantity) as Quantity,
   count(distinct(accountnum)) as num_of_customers,
   sum(sum_sqft) as sum_sqft ,states
   from c
   group by zip, chemical_name,states,final_measure
   
   
---Table used to reassign all the false names, false sprays , dates between current day and last spray and the unit of measure 
create table all_records(
   with adjust as (
select accountnum, date,employee, sitename,chemical,materialquantity,
case when chemical = 'Cyzmic Cs' or chemical = 'LIV Repeller' then 1 else 0 end as inacc ,
case when chemical like 'Duraflex%' or chemical like 'Cyzmic%' then 'Duraflex'
when chemical like 'Stryker%' then 'Stryker'
when chemical like 'Stop the Bite%' then 'Stop the Bite (STB) 6oz/gal'
when chemical ='Bifen' then 'Bifen'
when chemical= 'Pivot 10' then  'Pivot 10'
when chemical = 'EcoVia EC' or chemical = 'EcoVia G' or chemical = 'EvoVia G'then 'EcoVia G'
when chemical like 'Surf-Ac%' then 'Surf-Ac 820'
when chemical = 'EcoVia MT' then 'EcoVia MT'
when chemical = 'Aquabac (200G)' or chemical = 'AquaBacXT' then 'Aquabac (200G)'
when chemical = 'Tekko Pro' or chemical = 'Tekko 0.2G Larvicide (Low Rate)' or chemical = 'Tekko 0.2G Larvicide (High Rate)' then 'Tekko 0.2G Larvicide (High Rate)'
when chemical ='Altosid Pro-G' then 'Altosid Pro-G'
when chemical ='AquaBacXT' then 'AquaBacXT'
when chemical = 'In2Care Unit' then 'In2Care Unit'
when chemical = 'In2Mix Bait Sachets' then 'In2Mix Bait Sachets'
when chemical = 'Essentria IC3' then 'Essentria IC3'
when chemical = 'Bifen Granulars' then 'Bifen Granulars'
when chemical = 'Thermacell Tick Tubes' then 'Thermacell Tick Tubes'
when chemical = 'Summit Bti Dunks' then 'Summit Bti Dunks'
when chemical = 'B.T.I. Briquets' then 'B.T.I. Briquets'
when chemical = 'Summit BTI Granules' then 'Summit BTI Granules'
when chemical =  'LIV Repeller' then 'LIV Repeller' 
when chemical = 'Altosid' then 'Altosid'  end as chemical_name,
case when siteaddress like '%NH%' then 1 else 0 end as states,
(materialquantity * 5000) as squarefeet,siteaddress
from all_sprays)
,b as (select *,case when chemical_name= 'Duraflex' then 1
when chemical_name ='EcoVia MT' or chemical_name ='EcoVia G' then 0.5
when chemical_name = 'Stop the Bite (STB) 6oz/gal' then 6
when chemical_name = 'Stryker' then 10 
when chemical_name ='Altosid Pro-G' then 1 
when chemical_name ='Altosid' then 1
when chemical_name = 'Aquabac (200G)' then 1 
when chemical_name ='Bifen Granulars' then 1
when chemical_name ='Bifen' then 1
when chemical_name ='Pivot 10' then 4
when chemical_name ='Summit BTI Granules' or chemical_name ='Summit Bti Dunks' or chemical_name ='Thermacell Tick Tubes' or chemical_name = 'In2Care Unit' or chemical_name = 'In2Mix Bait Sachets' then 1
when chemical_name ='Surf-Ac 820' then 1.5 
when chemical_name ='Tekko 0.2G Larvicide (High Rate)' then 1
when chemical_name ='Essentria IC3' then 2 end as unit_multi,
case when chemical_name= 'Duraflex' then 'oz'
when chemical_name ='EcoVia MT' or chemical_name ='EcoVia G' then 'oz'
when chemical_name = 'Stop the Bite (STB) 6oz/gal' then 'oz'
when chemical_name = 'Stryker' then 'ml' 
when chemical_name ='Altosid Pro-G' or chemical_name = 'Altosid' then 'tsp'
when chemical_name = 'Aquabac (200G)' then 'tsp'
when chemical_name ='Bifen Granulars' then 'pound'
when chemical_name ='Bifen' then 'oz'
when chemical_name ='Pivot 10' then 'ml'
when chemical_name ='Summit Bti Dunks'or chemical_name ='Thermacell Tick Tubes' or chemical_name = 'In2Care Unit' or chemical_name = 'In2Mix Bait Sachets' or chemical_name = 'Summit BTI Granules' then 'each'
when chemical_name ='Surf-Ac 820' then 'ml' 
when chemical_name = 'Tekko 0.2G Larvicide (High Rate)' or chemical_name = 'Altosid' 
or chemical_name = 'Essentria IC3' or chemical_name = 'AquaBacXT' then 'oz' else 0 end as unitmeasure,current_date as today
from adjust)
select *,case when unitmeasure = 'oz' then 128
when unitmeasure = 'ml' then 29.5735
when unitmeasure = 'pound' then 1
when unitmeasure = 'tsp' then 96
when unitmeasure = 'each' then 1 end as divide,datediff(today,date) as days_since_spray
from b)
,datediff(days_seperating,date) as days_since_spray
current_date as days_since_spray FROM all_records
)
select *, datediff(days_since_spray,date) as days_since_spray
from a 




---Table used for finding the amounts each customer uses 

create table grouped_by_customer as(
with adjust as (
select accountnum, date,employee, sitename,chemical,materialquantity,
case when chemical = 'Cyzmic Cs' or chemical = 'LIV Repeller' then 1 else 0 end as inacc ,
case when chemical like 'Duraflex%' or chemical like 'Cyzmic%' then 'Duraflex'
when chemical like 'Stryker%' then 'Stryker'
when chemical like 'Stop the Bite%' then 'Stop the Bite (STB) 6oz/gal'
when chemical ='Bifen' then 'Bifen'
when chemical= 'Pivot 10' then  'Pivot 10'
when chemical = 'EcoVia EC' or chemical = 'EcoVia G' or chemical = 'EvoVia G'then 'EcoVia G'
when chemical like 'Surf-Ac%' then 'Surf-Ac 820'
when chemical = 'EcoVia MT' then 'EcoVia MT'
when chemical = 'Aquabac (200G)' or chemical = 'AquaBacXT' then 'Aquabac (200G)'
when chemical = 'Tekko Pro' or chemical = 'Tekko 0.2G Larvicide (Low Rate)' or chemical = 'Tekko 0.2G Larvicide (High Rate)' then 'Tekko 0.2G Larvicide (High Rate)'
when chemical ='Altosid Pro-G' then 'Altosid Pro-G'
when chemical ='AquaBacXT' then 'AquaBacXT'
when chemical = 'In2Care Unit' then 'In2Care Unit'
when chemical = 'In2Mix Bait Sachets' then 'In2Mix Bait Sachets'
when chemical = 'Essentria IC3' then 'Essentria IC3'
when chemical = 'Bifen Granulars' then 'Bifen Granulars'
when chemical = 'Thermacell Tick Tubes' then 'Thermacell Tick Tubes'
when chemical = 'Summit Bti Dunks' then 'Summit Bti Dunks'
when chemical = 'B.T.I. Briquets' then 'B.T.I. Briquets'
when chemical = 'Summit BTI Granules' then 'Summit BTI Granules'
when chemical =  'LIV Repeller' then 'LIV Repeller' 
when chemical = 'Altosid' then 'Altosid'  end as chemical_name,
case when siteaddress like '%NH%' then 1 else 0 end as states,
(materialquantity * 5000) as squarefeet,siteaddress
from all_sprays )
,b as (select *,case when chemical_name= 'Duraflex' then 1
when chemical_name ='EcoVia MT' or chemical_name ='EcoVia G' then 0.5
when chemical_name = 'Stop the Bite (STB) 6oz/gal' then 6
when chemical_name = 'Stryker' then 10 
when chemical_name ='Altosid Pro-G' then 1 
when chemical_name ='Altosid' then 1
when chemical_name = 'Aquabac (200G)' then 1 
when chemical_name ='Bifen Granulars' then 1
when chemical_name ='Bifen' then 1
when chemical_name ='Pivot 10' then 4
when chemical_name ='Summit BTI Granules' or chemical_name ='Summit Bti Dunks' or chemical_name ='Thermacell Tick Tubes' or chemical_name = 'In2Care Unit' or chemical_name = 'In2Mix Bait Sachets' then 1
when chemical_name ='Surf-Ac 820' then 1.5 
when chemical_name ='Tekko 0.2G Larvicide (High Rate)' then 1
when chemical_name ='Essentria IC3' then 2 end as unit_multi,
case when chemical_name= 'Duraflex' then 'oz'
when chemical_name ='EcoVia MT' or chemical_name ='EcoVia G' then 'oz'
when chemical_name = 'Stop the Bite (STB) 6oz/gal' then 'oz'
when chemical_name = 'Stryker' then 'ml' 
when chemical_name ='Altosid Pro-G' or chemical_name = 'Altosid' then 'tsp'
when chemical_name = 'Aquabac (200G)' then 'tsp'
when chemical_name ='Bifen Granulars' then 'pound'
when chemical_name ='Bifen' then 'oz'
when chemical_name ='Pivot 10' then 'ml'
when chemical_name ='Summit Bti Dunks'or chemical_name ='Thermacell Tick Tubes' or chemical_name = 'In2Care Unit' or chemical_name = 'In2Mix Bait Sachets' or chemical_name = 'Summit BTI Granules' then 'each'
when chemical_name ='Surf-Ac 820' then 'ml' 
when chemical_name = 'Tekko 0.2G Larvicide (High Rate)' or chemical_name = 'Altosid' or chemical_name = 'Essentria IC3' or chemical_name = 'AquaBacXT' then 'oz' else 0 end as unitmeasure
from adjust)
, c as(
select *,case when unitmeasure = 'oz' then 128
when unitmeasure = 'ml' then 29.5735
when unitmeasure = 'pound' then 1
when unitmeasure = 'tsp' then 96
when unitmeasure = 'each' then 1 end as divide
from b
)
, d as( 
select * ,case when unitmeasure = 'oz' then 'Gallons'
when unitmeasure = 'ml' then 'Oz'
when unitmeasure = 'pound' or unitmeasure = 'tsp' then 'Pounds'
when unitmeasure = 'each' then 'each' end as final_measure,
 (materialquantity * unit_multi)/divide as amount_in_unit
from c
)
select  states, accountnum,sitename, chemical_name,siteaddress,sum(materialquantity) as Quantity, sum(amount_in_unit) as Amount_used,final_measure, sum(squarefeet) as sum_sqft ,concat(unit_multi,unitmeasure) as Usage_per_quantity
from d
where date between '2022-01-01' and '2023-01-01' and  materialquantity > 1 
group by chemical_name,sitename, siteaddress, unit_multi,unitmeasure,accountnum,states
)



------Side Insight --------
---Count the number of reprays by customer 
select accountnum as Respray,count(distinct(completeddate)) as resprays
from Project.all_sprays
where eventname = 'Re-Spray'
GROUP BY accountnum
---Selecting the amount used per product
SELECT itemnum as Chemical, sum(usagepermixuom * materialquantity) as Amount_Used
FROM all_sprays 
WHERE completeddate 
BETWEEN '01/01/2022' AND '12/01/2022'
GROUP BY itemnum

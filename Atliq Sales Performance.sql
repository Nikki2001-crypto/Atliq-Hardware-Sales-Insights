
/*Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
business in the  APAC  region.*/

select 
distinct market
from  dim_customer
where customer='Atliq Exclusive'
and region='APAC'
order by market;

/* What is the percentage of unique product increase in 2021 vs. 2020? The 
final output contains these fields, 
unique_products_2020 
unique_products_2021 
percentage_chg 
*/

SELECT 
COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_products_2020,
COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_products_2021,
ROUND(
        (
            SUM(CASE WHEN fiscal_year = 2021 THEN 1 ELSE 0 END) -
            SUM(CASE WHEN fiscal_year = 2020 THEN 1 ELSE 0 END)
        ) * 100.0 /
        SUM(CASE WHEN fiscal_year = 2020 THEN 1 ELSE 0 END),
    2) AS percentage_chg
FROM (
    SELECT DISTINCT product_code, fiscal_year
    FROM fact_sales_monthly
    WHERE fiscal_year IN (2020, 2021)
) t;

/*Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
*/
select 
count(distinct product) as product_count ,
segment
from dim_product
group by 
segment
order by 
product_count desc;


/*
Follow-up: Which segment had the most increase in unique products in 
2021 vs 2020? The final output contains these fields, 
segment 
product_count_2020 
product_count_2021 
difference 
*/
select 
t1.segment,
COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN t1.product END) as r1,
COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN t1.product END) as r2,
COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN t1.product END)-COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN t1.product END) as diffrence
from dim_product t1
join fact_sales_monthly t2
on t1.product_code=t2.product_code
group by 
t1.segment
order by 
diffrence desc 
limit 1;


/* Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code 
product 
manufacturing_cost */

with An as(
select t1.product_code,
        t2.product,
        t1.manufacturing_cost,
row_number() over( order by manufacturing_cost desc ) as high,
row_number() over( order by manufacturing_cost Asc ) as low
from fact_manufacturing_cost t1
join dim_product t2
on t1.product_code=t2.product_code)
select 
product_code,
product,
manufacturing_cost
from An
where high=1 or low=1;


/*Generate a report which contains the top 5 customers who received an 
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
Indian  market. The final output contains these fields, 
customer_code 
customer 
average_discount_percentage */

select 
t1.customer_code,t2.customer,
Avg(t1.pre_invoice_discount_pct) as average_invoice 
from
fact_pre_invoice_deductions t1
join dim_customer t2
on t1.customer_code=t2.customer_code
where 
t1.fiscal_year=2021 and t2.market='india'
group by 
t1.customer_code , customer
order by 
average_invoice desc 
limit 5;




/*Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions. 
The final report contains these columns: 
Month 
Year 
Gross sales Amount */
select 
monthname(t2.date) as Month_wise,
t2.fiscal_year as year_wise,
round(sum(t2.sold_quantity*t3.gross_price),2) as 'gross_sale'
from 
dim_customer t1
join fact_sales_monthly t2
on t1.customer_code=t2.customer_code
join fact_gross_price t3
on t2.product_code=t3.product_code
and t2.fiscal_year=t3.fiscal_year
where 
customer='Atliq Exclusive'
GROUP BY 
    MONTHNAME(t2.date),
    t2.fiscal_year
order by
 MONTHNAME(t2.date),
    t2.fiscal_year;


 /*In which quarter of 2020, got the maximum total_sold_quantity? The final 
output contains these fields sorted by the total_sold_quantity, 
Quarter 
total_sold_quantity 
*/
SELECT 
QUARTER(date) AS quarter,
sum(sold_quantity) as 'total_sold_quantity'
FROM fact_sales_monthly
WHERE 
fiscal_year = 2020
AND date >= '2019-09-01'
AND date <= '2020-08-31'
group by 
QUARTER(date)
order by 
sum(sold_quantity) desc 
limit 1 ;

/*
Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?  The final output  contains these fields, 
channel 
gross_sales_mln 
percentage
*/
select 
t1.channel,
ROUND(SUM(t2.sold_quantity*t3.gross_price)/1000000,2) AS gross_sales_mln,
round(
sum(t2.sold_quantity*t3.gross_price)/sum(sum(t2.sold_quantity*t3.gross_price)) over() *100,2)as percentage
from dim_customer t1
join fact_sales_monthly t2
on t1.customer_code=t2.customer_code
join fact_gross_price t3
on t2.product_code=t3.product_code
and  t2.fiscal_year=t3.fiscal_year
where t2.fiscal_year=2021
group by t1.channel
order by sum(t2.sold_quantity*t3.gross_price) desc 
;



/*Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these 
fields, 
division 
product_code 
codebasics.io 
product 
total_sold_quantity 
rank_order
*/
 
with An as(
select 
t1.division,
t1.product_code,
t1.product,
sum(sold_quantity) as total_sold 
from dim_product t1
join fact_sales_monthly t2
on t1.product_code=t2.product_code
where t2.fiscal_year=2021
group by 
t1.division,
t1.product_code,
t1.product)

select *
from 
(
select 
division,
product_code,
product,
total_sold,
Dense_rank() over(
partition by division
order by total_sold desc ) AS dnk
    FROM An
) ranked
WHERE dnk <= 3;


-- 各订单总额（按有效订单总数）
create table 各月份总销额 as
select
braz_e.olist_orders_dataset.order_id,
braz_e.olist_customers_dataset.customer_unique_id,
DATE_FORMAT(braz_e.olist_orders_dataset.order_purchase_timestamp,'%Y-%M') year_m,
sum(braz_e.olist_order_items_dataset.price) over(partition by braz_e.olist_order_items_dataset.order_id) amount,
braz_e.olist_customers_dataset.customer_city
from braz_e.olist_order_items_dataset
LEFT JOIN braz_e.olist_orders_dataset
on braz_e.olist_orders_dataset.order_id = braz_e.olist_order_items_dataset.order_id
LEFT JOIN braz_e.olist_customers_dataset
on braz_e.olist_customers_dataset.customer_id = braz_e.olist_orders_dataset.customer_id
where braz_e.olist_orders_dataset.order_status != 'unavailable'
and braz_e.olist_orders_dataset.order_status != 'canceled'

-- 2.各产品（按product_id）销量（加入年份月份，地区，产品大类）（按有效订单总数）
create table 各产品（按product_id）销量 as
select
DISTINCT braz_e.olist_order_items_dataset.product_id,
braz_e.olist_products_dataset.product_category_name,
braz_e.product_category_name_translation.product_category_name_english,
DATE_FORMAT(braz_e.olist_orders_dataset.order_purchase_timestamp,'%Y-%M') year_m,
braz_e.olist_customers_dataset.customer_city,
count(braz_e.olist_order_items_dataset.order_id) over(partition by braz_e.olist_order_items_dataset.product_id) cnt
from braz_e.olist_order_items_dataset
LEFT JOIN braz_e.olist_orders_dataset
on braz_e.olist_orders_dataset.order_id = braz_e.olist_order_items_dataset.order_id
LEFT JOIN braz_e.olist_customers_dataset
on braz_e.olist_customers_dataset.customer_id = braz_e.olist_orders_dataset.customer_id
LEFT JOIN braz_e.olist_products_dataset
on braz_e.olist_products_dataset.product_id = braz_e.olist_order_items_dataset.product_id
LEFT JOIN braz_e.product_category_name_translation
on braz_e.product_category_name_translation.product_category_name = braz_e.olist_products_dataset.product_category_name
where braz_e.olist_orders_dataset.order_status != 'unavailable'
and braz_e.olist_orders_dataset.order_status != 'canceled'

-- 3.各城市从下单至送达的平均时间长度（按已送达订单总数）
create table 各城市从下单至送达的平均时间长度 as 
with a as 
(select
braz_e.olist_orders_dataset.order_id,
braz_e.olist_customers_dataset.customer_city,
DATE_FORMAT(braz_e.olist_orders_dataset.order_purchase_timestamp,'%Y-%M') year_m,
DATEDIFF(braz_e.olist_orders_dataset.order_delivered_customer_date,braz_e.olist_orders_dataset.order_purchase_timestamp) real_diff,
ABS(DATEDIFF(braz_e.olist_orders_dataset.order_delivered_customer_date,braz_e.olist_orders_dataset.order_estimated_delivery_date)) esti_diff
from braz_e.olist_orders_dataset
LEFT JOIN braz_e.olist_customers_dataset
on braz_e.olist_customers_dataset.customer_id = braz_e.olist_orders_dataset.customer_id
where braz_e.olist_orders_dataset.order_delivered_customer_date is not null)
SELECT
DISTINCT a.customer_city,
a.year_m,
avg(a.real_diff) over(partition by a.customer_city,a.year_m) avg_real_diff,
avg(a.esti_diff) over(partition by a.customer_city,a.year_m) avg_esti_diff
from a

-- 4.用户RFM评分（按有效订单总数）
create table 用户RFM评分 as
with a as
(select
braz_e.olist_customers_dataset.customer_unique_id,
braz_e.olist_customers_dataset.customer_city,
MAX(braz_e.olist_orders_dataset.order_purchase_timestamp) R,
COUNT(braz_e.olist_orders_dataset.order_id) F,
SUM(braz_e.olist_order_items_dataset.price) M
from braz_e.olist_orders_dataset
left join braz_e.olist_customers_dataset
on braz_e.olist_customers_dataset.customer_id = braz_e.olist_orders_dataset.customer_id
left join braz_e.olist_order_items_dataset
on braz_e.olist_order_items_dataset.order_id = braz_e.olist_orders_dataset.order_id
where braz_e.olist_orders_dataset.order_status != 'unavailable'
and braz_e.olist_orders_dataset.order_status != 'canceled'
GROUP BY braz_e.olist_customers_dataset.customer_unique_id,braz_e.olist_customers_dataset.customer_city
),

b as 
(select
a.*,
NTILE(5) over(ORDER BY a.R desc) R_n,
NTILE(5) over(ORDER BY a.F desc) F_n,
NTILE(5) over(ORDER BY a.M desc) M_n
from a)

select
b.customer_unique_id,
b.customer_city,
b.R,
b.F,
b.M,
case b.R_n
	when 1 then 5
	when 2 then 4
	when 3 then 3
	when 4 then 2
	when 5 then 1
	end R_rating,
case b.F_n
	when 1 then 5
	when 2 then 4
	when 3 then 3
	when 4 then 2
	when 5 then 1
	end F_rating,
case b.M_n
	when 1 then 5
	when 2 then 4
	when 3 then 3
	when 4 then 2
	when 5 then 1
	end M_rating
from b





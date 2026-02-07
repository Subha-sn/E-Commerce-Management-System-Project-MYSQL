create database E_commerce;
use E_commerce;
describe customers;
select * from customers;
describe orders;
alter table orders modify column order_date date;
select * from orders;
describe payments;
select * from payments;
describe products;
select * from products;
describe shipping ;
select * from shipping;
------------------------------------------------------------------------------
-- primary key and foreign key
select * from orders;
select * from products;
select * from payments;
alter table orders add primary key(order_id);
alter table customers add primary key(customer_id);
alter table products add primary key(product_id);
alter table payments add primary key(order_id);
alter table shipping add primary key(order_id);
------
-- order -> customer
alter table orders add constraint order_customer_fk foreign key(customer_id) references customers(customer_id);

-- order -> products
alter table orders add constraint order_product_fk foreign key(product_id) references products(product_id);

-- payments -> order
alter table payments add constraint order_payment_fk foreign key(order_id) references orders(order_id);

-- shipping -> order
alter table shipping add constraint order_shipping_fk foreign key(order_id) references orders(order_id);
----------------------------------------------------

/* Project Task1 :
Update loyalty points for customers based on age.
  -age <25 then add 10 loyalty points
  -age between 25 and 40 then add 20  loyalty points
  -otherwise add 5 loyalty points */

select * from customers;
select * from customers;
update customers set loyalty_points=loyalty_points+
case when age <25 then 10
when age >=25 and age <40 then 20
else 5
end;
------------------------------------------------------------------------------------------------------------------------------
/* 2.Get total order value per country and classify sales category.
 -Hint: (Sales category Criteria)
 -sum(order_value) >100000 then "High"
 -sum(order_Value) between 50000 and 100000 then "medium"
*/

select * from orders; -- o
select * from customers; -- c
select c.country, round(sum(o.order_value)) as order_valu_sum,
case
when round(sum(order_value)) >100000 then "High"
when round(sum(order_value)) <= 50000 and round(sum(order_value))> 100000 then "medium"
else "low"
end as sales_category
from customers c join orders o on c.customer_id=o.customer_id 
group by c.country order by c.country;

------------------------------------------------------------------------------------------------------------------------------------------------

/*3.Pivot total order quantity per payment method
 -Hint:Payment_method = 'credit card" then add qty(Group) as Credit_card_qty
 -payment_method = 'paypal' then  add qty(Group) as pay_pal_qty
-payment_method = 'cash' then add qty (group) as cash_qty*/
select * from payments;
select * from orders;
select payment_method,
sum(case when Payment_method ='credit card' then (quantity)
else null end) as Credit_card_qty,
sum(case when Payment_method ='Bank Transfer' then (quantity)
else null end) as Bank_Transfer_qty,
sum(case when Payment_method ='Paypal' then (quantity)
else null end) as Paypal_qty,
sum(case when Payment_method ='cash' then (quantity)
else null end) as cash_qty,
sum(quantity) as Total_qty
from orders group by payment_method;
----------------------------------------------------------------------------------------------------------------------------------------------------------------

/* 4 (Joins with Subquery) Find top 3 customers by total order value and Customer_id (using Rank).
•	-Hint: Write an SQL query to retrieve the top 3 customers who have spent the highest total amount across all their orders. 
    -Hint: Write an SQL query to retrieve the top 3 customers who have spent the highest total amount across all their orders
 */
select * from customers;
select customer_id,customer_name,customer_order_value from
(select c.customer_id,c.customer_name,sum(o.order_value) as customer_order_value,
rank()over(order by sum(o.order_value) desc) from customers c
join orders o on c.customer_id=o.customer_id
group by c.customer_id,c.customer_name) as customer_rank
order by customer_order_value desc limit 3;
------------------------------------------------------------------------------------------------------------------------------------------

/* 5 Find products that have been ordered more than the average quantity.
   -Hint : Write an SQL query to identify products that are ordered in quantities higher than the average order quantity across all products.
*/
select * from orders;
select * from products;
select p.product_id,product_name,sum(o.quantity) as total_quantity 
from orders o join products p on p.product_id=o.product_id
group by product_id,product_name having sum(quantity)>
(select avg(quantity) from orders);
---------------------------------------------------------------------------------------------------------------------------------------------------

/* 6.Get all orders for a specific customer using customer_id
	-Hint : stored in procedures using In parameter
*/
select * from customers;
select * from orders;
delimiter //
create procedure customer_order(in cus_id int)
begin
select * from customers c join orders o on c.customer_id=o.customer_id where c.customer_id=cus_id;
end //
delimiter ;

call customer_order(53);
-------------------------------------------------------------------------------------------------------------------------------------------

/* 7 Return the total spending of a customer.
	Hint : stored in procedure using in out parameter and then return the spending customers
*/
select * from customers;
select * from orders;
delimiter //
create procedure customer_spendingg(in cus_id int, inout cust_spending int)
begin
select sum(order_value) into cust_spending from orders where customer_id=cus_id;
end //
delimiter ;
call customer_spending(43,@cust_spending);
select @cust_spending;
drop procedure customer_spendingg;
 -----------------------------------------------------------------------------------------------------------------------------------------------------------
 
 /* 8.Automatically set loyalty points to 0 if NULL on insert.
	-Hint: apply triggers using before insert
*/
 select * from customers;
delimiter //
create trigger loyalty_null before insert on customers for each row
begin
if new.loyalty_points is null then 
set new.loyalty_points= 0;
end if;
end //
delimiter ; 
select * from customers where customer_id=5001;

 insert into customers values (5001,'subha krish',null,null,null,null,null,null,null,null);
 ---------------------------------------------------------------------------------------------------------------------------------------------------
 
/* 9.After a new order is inserted, deduct quantity from product stock.
	-Hint1 : apply triggers using after insert(Insert event)
	-Hint2: In the concept of triggers, when an event is inserted using an AFTER INSERT trigger, the corresponding data should be updated in the secondary table.
*/
-- After a new order is inserted, deduct quantity from product stock.
-- Primary table
select * from orders;
-- secondary table
select * from products;

delimiter //
create trigger product_stock after insert on orders for each row
begin
update products p join orders o on p.product_id=o.product_id
set p.stock_quantity=p.stock_quantity - new.quantity where p.product_id=new.product_id;
end //
delimiter ;

insert into orders values(5001, 3042, 7,'2026-01-31',null,7,null,null,null,null); 
insert into orders values(5002, 3072, 1,'2026-01-31',null,6,null,null,null,null);
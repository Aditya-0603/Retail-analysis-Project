## create database
create database retail;
## create tables
use retail;
-- Geolocation
create table geolocation(
geolocation_zip_code_prefix int not null,
geolocation_lat text not null,
geolocation_lng text not null,
geolocation_city varchar(225) not null,
geolocation_state varchar(225) not null);
-- Customers
create table customers(
customer_id varchar(225) primary key,
customer_unique_id varchar(225) not null,
customer_zip_code_prefix int not null,
customer_city varchar(225) not null,
customer_state varchar(225) not null);
-- Sellers
create table sellers(
seller_id varchar(225) primary key,
seller_zip_code_prefix int not null,
seller_city varchar(225) not null,
seller_state varchar(100) not null);
-- Products
create table products(
product_id varchar(225) primary key,
`product category` varchar(225) null,
product_name_length text null,
product_description_length text null,
product_photos_qty text null,
product_weight_g text null,
product_length_cm text null,
product_height_cm text null,
product_width_cm text null);
-- Orders
create table orders(
order_id varchar(225) primary key,
customer_id varchar(225) not null,
order_status varchar(225) not null,
order_purchase_timestamp text not null,
order_approved_at text null,
order_delivered_carrier_date text null,
order_delivered_customer_date text null,
order_estimated_delivery_date text not null,
foreign key(customer_id) references customers(customer_id));
-- Payments
create table payments(
order_id varchar(225),
payment_sequential tinyint not null,
payment_type varchar(225) not null,
payment_installments tinyint not null,
payment_value decimal not null,
foreign key(order_id) references orders(order_id));
-- Order_review
create table order_review(
review_id varchar(225) primary key,
order_id varchar(225),
review_score tinyint not null,
review_comment_title text,
review_creation_date text not null,
review_answer_timestamp text not null,
foreign key(order_id) references orders(order_id));
-- order_item
create table order_item(
order_id varchar(225),
order_item_id char(20),
product_id varchar(225),
seller_id varchar(225),
shipping_limit_date text not null,
price text not null,
freight_value decimal not null,
foreign key(order_id) references orders(order_id),
foreign key(product_id) references products(product_id),
foreign key(seller_id) references sellers(seller_id));


# --------------------------------------------------------------------------------------------


use retail;
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';
## geolocation
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/geolocation.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(geolocation_zip_code_prefix, geolocation_lat ,geolocation_lng,
geolocation_city, geolocation_state);
## customers
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv'
INTO
TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city,
customer_state);
## sellers
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sellers.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(seller_id, seller_zip_code_prefix, seller_city, seller_state
);
## products
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, `product category`, product_name_length, product_description_length,
product_photos_qty, product_weight_g,
product_length_cm, product_height_cm, product_width_cm);
## orders
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at,
order_delivered_carrier_date,
order_delivered_customer_date, order_estimated_delivery_date);
## payments
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/payments.csv'
INTO TABLE payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id ,payment_sequential ,payment_type, payment_installments
,payment_value
);
## Order_review
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_reviews.csv'
REPLACE
INTO TABLE order_review
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(review_id, order_id, review_score, review_creation_date, review_answer_timestamp);

## order_item
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_items.csv'
REPLACE
INTO TABLE order_item
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id, shipping_limit_date,
price, freight_value
);
select count(*) from geolocation;
select count(*) from customers;
select count(*) from sellers;
select count(*) from products;
select count(*) from orders;
select count(*) from payments; 
select count(*) from order_review; #
select count(*) from order_item;





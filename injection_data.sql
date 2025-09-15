---Création de la base de données et des schéma---
CREATE OR REPLACE WAREHOUSE chanel_wh
WITH
WAREHOUSE_SIZE='X-Small'
AUTO_SUSPEND=300
AUTO_RESUME=TRUE
MIN_CLUSTER_COUNT=1
MAX_CLUSTER_COUNT=3;

USE WAREHOUSE chanel_wh;


CREATE OR REPLACE DATABASE chanelhub
data_retention_time_in_days = 7;

CREATE OR REPLACE SCHEMA chanelhub.raw;
CREATE OR REPLACE SCHEMA chanelhub.stg;
CREATE OR REPLACE SCHEMA chanelhub.core;
CREATE OR REPLACE SCHEMA chanelhub.marts;

-- création des formats (CSV & JSON Lines)
CREATE OR REPLACE FILE FORMAT chanelhub.raw.file_format_csv
TYPE = CSV
FIELD_DELIMITER = ','
PARSE_HEADER = TRUE
COMPRESSION = AUTO
DATE_FORMAT='YYYY-MM-DD'
FIELD_OPTIONALLY_ENCLOSED_BY='"'
ERROR_ON_COLUMN_COUNT_MISMATCH=FALSE;

CREATE OR REPLACE FILE FORMAT chanelhub.raw.ff_jsonl
  TYPE = JSON
  STRIP_OUTER_ARRAY = FALSE
  COMPRESSION = AUTO;

---Creation des storage integration
CREATE OR REPLACE STORAGE INTEGRATION s3_integration
TYPE=EXTERNAL_STAGE
STORAGE_PROVIDER=S3
ENABLED=TRUE
STORAGE_AWS_ROLE_ARN='arn:aws:iam::193278870299:role/snowrole'
STORAGE_ALLOWED_LOCATIONS=(
's3://snowdbtbuck0101/retail/Products_Master/',
's3://snowdbtbuck0101/retail/orders/',
's3://snowdbtbuck0101/retail/order_items/',
's3://snowdbtbuck0101/logistics/',
's3://snowdbtbuck0101/marketing/campaigns/',
's3://snowdbtbuck0101/marketing/events/',
's3://snowdbtbuck0101/rds/customers/',
's3://snowdbtbuck0101/rds/inventories/'
);
----pour obtenir les propriétés STORAGE_AWS_IAM_USER_ARN et STORAGE_AWS_EXTERNAL_ID pour configuration de la Trust policy
desc storage integration s3_integration;

-- creation des tables en adoptant un schéma en étoile
create or replace table chanelhub.raw.dim_customers(
customer_ext_id STRING,
first_name STRING,
last_name STRING,
email_hash STRING,
country STRING,
filename STRING
);


create or replace table chanelhub.raw.dim_products_master(
sku varchar,
collection STRING,
category STRING,
price_list NUMERIC(20, 7),
filename STRING
);

CREATE OR REPLACE TABLE chanelhub.raw.dim_campaigns (
  campaign_id STRING,
  name        STRING,
  market      STRING,
  start_dt    DATE,
  end_dt      DATE,
  objective   STRING,
  channel1    STRING,
  channel2    STRING,
  channel3    STRING,
  filename    STRING
);

create or replace table chanelhub.raw.fact_orders(
order_id STRING,
order_dt DATE,
store_code STRING,
channel STRING,
customer_ext_id STRING,
currency STRING,
filename STRING
);

create or replace table chanelhub.raw.fact_order_items(
order_id STRING,
order_item_id STRING,
sku STRING,
qty INT,
unit_price NUMERIC(20, 7),
discount_amount NUMERIC(20, 7),
tax_amount NUMERIC(20, 7),
filename STRING
);

create or replace table chanelhub.raw.fact_inventory(
sku STRING,
warehouse_code STRING,
qty_on_hand INT,
qty_reserved INT,
filename STRING
);

CREATE OR REPLACE TABLE chanelhub.raw.fact_web_events (
  event_id     STRING,
  session_id   STRING,
  event_type   STRING,
  event_ts     TIMESTAMP_NTZ,
  device       STRING,
  source       STRING,
  medium       STRING,
  campaign_id  STRING,
  order_id     STRING,
  filename     STRING
);

CREATE OR REPLACE TABLE chanelhub.raw.fact_shipments (
  shipment_id    STRING,
  order_id       STRING,
  status         STRING,
  event_ts       TIMESTAMP_NTZ,
  warehouse_code STRING,
  units          NUMBER,
  weight_kg      FLOAT,
  carrier        STRING,
  ship_cost      FLOAT,
  filename       STRING  
);

---creation des stages---
CREATE OR REPLACE STAGE stg_customers
file_format=(FORMAT_NAME=chanelhub.raw.file_format_csv)
storage_integration=s3_integration
URL='s3://snowdbtbuck0101/rds/customers/';

CREATE OR REPLACE STAGE stg_orders
file_format=(FORMAT_NAME=chanelhub.raw.file_format_csv)
storage_integration=s3_integration
URL='s3://snowdbtbuck0101/retail/orders/';

CREATE OR REPLACE STAGE stg_order_items
file_format=(FORMAT_NAME=chanelhub.raw.file_format_csv)
storage_integration=s3_integration
URL='s3://snowdbtbuck0101/retail/order_items/';

CREATE OR REPLACE STAGE stg_products_master
file_format=(FORMAT_NAME=chanelhub.raw.file_format_csv)
storage_integration=s3_integration
URL='s3://snowdbtbuck0101/retail/Products_Master/';

CREATE OR REPLACE STAGE stg_inventory
file_format=(FORMAT_NAME=chanelhub.raw.file_format_csv)
storage_integration=s3_integration
URL='s3://snowdbtbuck0101/rds/inventories/';

CREATE OR REPLACE STAGE stg_shipments
file_format=(FORMAT_NAME=chanelhub.raw.ff_jsonl)
storage_integration=s3_integration
URL='s3://snowdbtbuck0101/logistics/';

CREATE OR REPLACE STAGE  stg_campaigns
file_format=(FORMAT_NAME=chanelhub.raw.ff_jsonl)
storage_integration=s3_integration
URL='s3://snowdbtbuck0101/marketing/campaigns/';

CREATE OR REPLACE STAGE stg_web_events
file_format=(FORMAT_NAME=chanelhub.raw.ff_jsonl)
storage_integration=s3_integration
URL='s3://snowdbtbuck0101/marketing/events/';

list @stg_web_events;
--- Injection continue des données dans les tables------
CREATE OR REPLACE PIPE chanelhub.raw.customers_pipe
AUTO_INGEST = TRUE
AS
COPY INTO chanelhub.raw.dim_customers
FROM @chanelhub.raw.stg_customers
on_error=CONTINUE
MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE
INCLUDE_METADATA = (filename = METADATA$FILENAME);

CREATE OR REPLACE PIPE products_master_pipe
AUTO_INGEST=TRUE
AS
COPY INTO chanelhub.raw.dim_products_master
FROM @chanelhub.raw.stg_products_master
on_error=CONTINUE
MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE
INCLUDE_METADATA = (filename = METADATA$FILENAME);

CREATE OR REPLACE PIPE orders_pipe
AUTO_INGEST=TRUE
AS
COPY INTO chanelhub.raw.fact_orders
FROM @chanelhub.raw.stg_orders
on_error=CONTINUE
MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE
INCLUDE_METADATA = (filename = METADATA$FILENAME);

CREATE OR REPLACE PIPE order_items_pipe
AUTO_INGEST=TRUE
AS
COPY INTO chanelhub.raw.fact_order_items
FROM @chanelhub.raw.stg_order_items
on_error=CONTINUE
MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE
INCLUDE_METADATA = (filename = METADATA$FILENAME);

CREATE OR REPLACE PIPE inventory_pipe
AUTO_INGEST=TRUE
AS
COPY INTO chanelhub.raw.fact_inventory
FROM @chanelhub.raw.stg_inventory
on_error=CONTINUE
MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE
INCLUDE_METADATA = (filename = METADATA$FILENAME);

CREATE OR REPLACE PIPE campaigns_pipe
AUTO_INGEST = TRUE
AS
COPY INTO chanelhub.raw.dim_campaigns
  (campaign_id, name, market, start_dt, end_dt, objective, channel1, channel2, channel3, filename)
FROM (
  SELECT
    $1:campaign_id::STRING,
    $1:name::STRING,
    $1:market::STRING,
    TO_DATE($1:start_dt::STRING, 'YYYY-MM-DD'),
    TO_DATE($1:end_dt::STRING,   'YYYY-MM-DD'),
    $1:objective::STRING,
    $1:channels[0]::STRING,
    $1:channels[1]::STRING,
    $1:channels[2]::STRING,
    METADATA$FILENAME
  FROM @chanelhub.raw.stg_campaigns
)
FILE_FORMAT = (FORMAT_NAME = chanelhub.raw.ff_jsonl)
ON_ERROR = 'CONTINUE';

CREATE OR REPLACE PIPE web_events_pipe
AUTO_INGEST = TRUE
AS
COPY INTO chanelhub.raw.fact_web_events
  (event_id, session_id, event_type, event_ts, device, source, medium, campaign_id, order_id, filename)
FROM (
  SELECT
    $1:event_id::STRING,
    $1:session_id::STRING,
    $1:event_type::STRING,
    TO_TIMESTAMP_NTZ($1:event_ts::STRING),
    $1:device::STRING,
    $1:source::STRING,
    $1:medium::STRING,
    $1:campaign_id::STRING,
    $1:order_id::STRING,
    METADATA$FILENAME
  FROM @chanelhub.raw.stg_web_events
)
FILE_FORMAT = (FORMAT_NAME = chanelhub.raw.ff_jsonl)
ON_ERROR = 'CONTINUE';

CREATE OR REPLACE PIPE pipe_shipments
AUTO_INGEST = TRUE
AS
COPY INTO chanelhub.raw.fact_shipments
  (shipment_id, order_id, status, event_ts, warehouse_code, units, weight_kg, carrier, ship_cost, filename)
FROM (
  SELECT
    $1:shipment_id::STRING,
    $1:order_id::STRING,
    $1:status::STRING,
    TO_TIMESTAMP_NTZ($1:event_ts::STRING),
    $1:warehouse_code::STRING,
    $1:units::NUMBER,
    $1:weight_kg::FLOAT,
    $1:carrier::STRING,
    $1:ship_cost::FLOAT,
    METADATA$FILENAME
  FROM @chanelhub.raw.stg_shipments
)
FILE_FORMAT = (FORMAT_NAME = chanelhub.raw.ff_jsonl)
ON_ERROR = 'CONTINUE';

---Requêtes de checkin et config d'un event notification--------------------
show pipes;
select SYSTEM$PIPE_STATUS('chanelhub.raw.customers_pipe');
select SYSTEM$PIPE_STATUS('orders_pipe');

select * from chanelhub.raw.CHANELHUB.STG;
select * from chanelhub.raw.dim_products_master;
select * from chanelhub.raw.dim_campaigns;
select * from chanelhub.raw.fact_orders;
select * from fact_order_items;
select * from chanelhub.raw.fact_inventory;
select * from chanelhub.raw.fact_web_events;
select * from chanelhub.raw.fact_shipments;

---Requêtes sur les vues du staging(STG)
select * from CHANELHUB.STG.STG_CUSTOMERS;
select * from CHANELHUB.STG.STG_COMPAIGNS;
select * from CHANELHUB.STG.STG_EVENTS;
select * from CHANELHUB.STG.STG_INVENTORY;
select * from CHANELHUB.STG.STG_ORDERS;
select * from CHANELHUB.STG.STG_ORDER_ITEMS;
select * from CHANELHUB.STG.STG_PRODUCTS;
select * from CHANELHUB.STG.STG_SHIPMENTS;
select * from CHANELHUB.CORE.FACT_ORDERS_AND_EVENTS;

select
canal, count(*) 
from CHANELHUB.CORE.FACT_SALES
group by canal;

select code_magasin, count(*) from CHANELHUB.CORE.DIM_STORE group by code_magasin;
select * from CHANELHUB.CORE.FACT_INVENTORY;
select * from CHANELHUB.CORE.FACT_ORDERS_AND_EVENTS;
select * from CHANELHUB.MARTS.FACT_VIEW_SHIPMENTS A
join CHANELHUB.MARTS.FACT_VIEW_ORDERS_AND_EVENTS B
USING(order_id);

select SYSTEM$PIPE_STATUS('chanelhub.raw.orders_pipe');

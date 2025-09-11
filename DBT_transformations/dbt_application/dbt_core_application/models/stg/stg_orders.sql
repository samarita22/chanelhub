WITH orders AS(
    SELECT 
        order_id ,
        to_date(order_dt) as date_commande,
        store_code as code_magasin,
        upper(channel) as canal,
        customer_ext_id as client_id,
        currency as devise,
        filename STRING
    FROM {{source('channel_raw_data','fact_orders')}}
)
SELECT * FROM orders
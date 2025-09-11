WITH customers AS(
    SELECT customer_ext_id as client_id, 
        first_name as prenom, 
        upper(last_name) as nom, 
        email_hash as email_hash, 
        country pays, 
        filename
    FROM {{source('channel_raw_data', 'dim_customers')}}
)
SELECT * FROM customers

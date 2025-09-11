WITH products AS( 
    SELECT 
        sku as product_id,
        collection as gamme,
        category as categorie,
        price_list as prix_reference,
        filename
    FROM {{source('channel_raw_data','dim_products_master')}}
)
SELECT * FROM products
{{config(materialized="table")}}

    SELECT 
    product_id,
    gamme,
    categorie,
    prix_reference
    FROM {{ref('stg_products')}}
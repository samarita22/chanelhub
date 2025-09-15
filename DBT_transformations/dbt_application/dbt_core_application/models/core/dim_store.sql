{{config(materialized="table")}}

SELECT 
    code_magasin
FROM {{ref('stg_orders')}}
{{config(materialized="table")}}

WITH all_warehouses AS(
    (
        SELECT code_entrepot
        FROM {{ref('stg_inventory')}}
    )
    UNION   
    (
        SELECT code_entrepot 
        FROM {{ref('stg_shipments')}}
    )
)

SELECT * FROM all_warehouses
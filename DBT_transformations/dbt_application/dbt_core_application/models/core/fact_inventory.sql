{{config(materialized="table")}}
    SELECT * exclude(filename)
    FROM {{ref('stg_inventory')}}
{{config(materialized="view")}}

    SELECT * 
    FROM {{ref('fact_orders_and_events')}}
{{config(materialized="table")}}

    SELECT 
        client_id,
        prenom,
        nom,
        email_hash,
        pays
    FROM {{ref('stg_customers')}}


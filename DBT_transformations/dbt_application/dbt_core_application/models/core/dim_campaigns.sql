{{config(materialized="view")}}
SELECT 
    campaign_id,
    nom_campagne,
    marche,
    date_debut,
    date_fin,
    duree_jours,
    objectif,
    canal1,
    canal2,
    canal3
FROM {{ref('stg_compaigns')}}

WITH campaigns AS(
    SELECT 
        campaign_id,
        name as nom_campagne,
        market as marche,
        start_dt  as date_debut,
        end_dt  as date_fin,
        (end_dt - start_dt) as duree_jours,
        objective as objectif,
        channel1 as canal1,
        channel2  as canal2,
        channel3 as canal3,
        filename 
    FROM {{source('channel_raw_data', 'dim_campaigns')}}
)
SELECT * FROM campaigns
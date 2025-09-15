{{config(materialized="table")}}

WITH order_items AS( 
    SELECT 
        order_id,
        order_item_id,
        product_id,
        quantite,
        prix_unitaire,
        montant_remise,
        montant_taxe,
        montant_brut,
        montant_net
    FROM {{ref('stg_order_items')}}
),

events AS(
    SELECT 
        event_id,
        session_id,
        type_evenement,
        date_evenement,
        appareil,
        source,
        support,
        order_id
    FROM {{ref('stg_events')}}  
),

both_order_items_and_events AS(
    SELECT 
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.quantite,
        oi.prix_unitaire,
        oi.montant_remise,
        oi.montant_taxe,
        oi.montant_brut,
        oi.montant_net,
        e.event_id,
        e.session_id,
        e.type_evenement,
        e.date_evenement,
        e.appareil,
        e.source,
        e.support
    FROM order_items oi
    LEFT JOIN events e
    ON oi.order_id = e.order_id
)

select * from both_order_items_and_events
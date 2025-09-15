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

orders AS(
    SELECT
        order_id,
        date_commande,
        code_magasin,
        canal,
        client_id,
        devise
    FROM {{ref('stg_orders')}}
),

both_order_and_other_items AS(
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
        o.date_commande,
        o.code_magasin,
        o.canal,
        o.client_id,
        o.devise
    FROM order_items oi
    INNER JOIN orders o
    ON oi.order_id = o.order_id
)

SELECT * from both_order_and_other_items
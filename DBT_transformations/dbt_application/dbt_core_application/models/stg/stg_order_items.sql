WITH order_items AS(
    SELECT 
        order_id,
        order_item_id,
        sku as product_id,
        qty as quantite,
        unit_price as prix_unitaire,
        discount_amount as montant_remise,
        tax_amount as montant_taxe,
        qty * unit_price as montant_brut,
        (qty * unit_price - discount_amount + tax_amount) as montant_net,
        filename
    FROM {{source('channel_raw_data','fact_order_items')}}
)
SELECT * FROM order_items
WITH inventory AS(
    SELECT 
        sku as product_id,
        warehouse_code as code_entrepot,
        qty_on_hand as quantite_stockee,
        qty_reserved as quantite_reservee,
        (qty_on_hand - qty_reserved) as quantite_restante,
        filename
    FROM {{source('channel_raw_data','fact_inventory')}}
)
SELECT * FROM inventory
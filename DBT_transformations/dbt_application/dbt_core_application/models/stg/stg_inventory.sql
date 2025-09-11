WITH inventory AS(
    SELECT 
        sku as product_id,
        warehouse as entrepot,
        qty_available as quantite_disponible,
        qty_on_hand as quantite_stockee,
        qty_reserved as quantite_reservee,
        (qty_on_hand - qty_reserved) as quantite_restante,
        filename
    FROM {{source('channel_raw_data','fact_inventory')}}
)
SELECT * FROM inventory
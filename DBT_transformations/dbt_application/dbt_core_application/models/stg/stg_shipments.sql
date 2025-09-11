WITH shipments AS (
    SELECT
        shipment_id,
        order_id,
        status,
        event_ts as date_expedition,
        warehouse_code as code_entrepot,
        units as quantite,
        weight_kg as poids_kg,
        carrier  as transporteur,
        ship_cost as cout_expedition,
        filename
    FROM {{ source('channel_raw_data', 'fact_shipments') }}
)
SELECT * FROM shipments
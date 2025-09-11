WITH events AS(
    SELECT 
        event_id,
        session_id,
        event_type as type_evenement,
        to_date(event_ts) as date_evenement,
        device as appareil,
        source,
        medium as support,
        campaign_id,
        order_id,
        filename
    FROM {{source('channel_raw_data','fact_events')}}
)
SELECT * FROM events
{{
    config(
        materialized = 'incremental',
        unique_key=['flight_date', 'airport_code', 'linked_airport_code']
    )
}}

WITH arrivals AS (
    SELECT 
        DATE(f.actual_arrival) AS flight_date,
        f.arrival_airport AS airport_code,
        f.departure_airport AS linked_airport_code,
        COUNT(DISTINCT f.flight_id) AS flights_in,
        COUNT(DISTINCT tf.ticket_no) AS passengers_in
    FROM {{ ref('flights') }} f
    LEFT JOIN {{ ref('ticket_flights') }} tf ON f.flight_id = tf.flight_id
    WHERE f.actual_arrival IS NOT NULL
    GROUP BY DATE(f.actual_arrival), f.arrival_airport, f.departure_airport
),
departures AS (
    SELECT 
      DATE(f.actual_departure) AS flight_date,
      f.departure_airport AS airport_code,
      f.arrival_airport AS linked_airport_code,
      COUNT(DISTINCT f.flight_id) AS flights_out,
      COUNT(DISTINCT tf.ticket_no) AS passengers_out
    FROM {{ ref('flights') }} f
    LEFT JOIN {{ ref('ticket_flights') }} tf ON f.flight_id = tf.flight_id
    WHERE f.actual_departure IS NOT NULL
    GROUP BY DATE(f.actual_departure), f.departure_airport, f.arrival_airport
),
combined AS (
    SELECT 
        flight_date,
        airport_code,
        linked_airport_code,
        flights_in,
        0 AS flights_out,
        passengers_in,
        0 AS passengers_out
    FROM arrivals
    UNION ALL
    SELECT 
        flight_date,
        airport_code,
        linked_airport_code,
        0 AS flights_in,
        flights_out,
        0 AS passengers_in,
        passengers_out
    FROM departures
)
SELECT 
    NOW() AS created_at,
    flight_date,
    airport_code,
    linked_airport_code,
    SUM(flights_in) AS flights_in,
    SUM(flights_out) AS flights_out,
    SUM(passengers_in) AS passengers_in,
    SUM(passengers_out) AS passengers_out
FROM combined
GROUP BY flight_date, airport_code, linked_airport_code
ORDER BY flight_date, airport_code, linked_airport_code

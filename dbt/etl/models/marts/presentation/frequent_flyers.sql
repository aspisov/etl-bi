WITH passenger_flights AS (
  -- Join tickets with ticket_flights to capture each flight per passenger along with the amount paid
  SELECT
    t.passenger_id,
    t.passenger_name,
    tf.flight_id,
    tf.amount
  FROM {{ ref('tickets') }} t
  JOIN {{ ref('ticket_flights') }} tf ON t.ticket_no = tf.ticket_no
),
agg AS (
  -- Aggregate by passenger: count flights and sum amounts
  SELECT
    passenger_id,
    passenger_name,
    COUNT(flight_id) AS flights_number,
    SUM(amount) AS purchase_sum
  FROM passenger_flights
  GROUP BY passenger_id, passenger_name
),
passenger_airports AS (
  -- For each flight taken by a passenger, consider both departure and arrival airports
  SELECT
    t.passenger_id,
    f.departure_airport AS airport_code
  FROM {{ ref('tickets') }} t
  JOIN {{ ref('ticket_flights') }} tf ON t.ticket_no = tf.ticket_no
  JOIN {{ ref('flights') }} f ON tf.flight_id = f.flight_id
  UNION ALL
  SELECT
    t.passenger_id,
    f.arrival_airport AS airport_code
  FROM {{ ref('tickets') }} t
  JOIN {{ ref('ticket_flights') }} tf ON t.ticket_no = tf.ticket_no
  JOIN {{ ref('flights') }} f ON tf.flight_id = f.flight_id
),
home_airport_agg AS (
  -- Count frequency of each airport per passenger and pick the one with the highest count.
  -- In case of ties, ORDER BY airport_code ASC ensures the alphabetically first is chosen.
  SELECT
    passenger_id,
    airport_code,
    ROW_NUMBER() OVER (PARTITION BY passenger_id ORDER BY COUNT(*) DESC, airport_code ASC) AS rn
  FROM passenger_airports
  GROUP BY passenger_id, airport_code
),
ranked AS (
  -- Compute the percentile rank over purchase_sum (higher sums get lower percent_rank values).
  SELECT
    a.*,
    percent_rank() OVER (ORDER BY purchase_sum DESC) AS pr
  FROM agg a
)
SELECT
  now() AS created_at,
  r.passenger_id,
  r.passenger_name,
  r.flights_number,
  r.purchase_sum,
  ha.airport_code AS home_airport,
  CASE
    WHEN r.pr <= 0.05 THEN '5'
    WHEN r.pr <= 0.10 THEN '10'
    WHEN r.pr <= 0.25 THEN '25'
    WHEN r.pr <= 0.50 THEN '50'
    ELSE '50+'
  END AS customer_group
FROM ranked r
LEFT JOIN (
  -- Select the most frequent airport (home_airport) per passenger
  SELECT passenger_id, airport_code
  FROM home_airport_agg
  WHERE rn = 1
) ha ON r.passenger_id = ha.passenger_id

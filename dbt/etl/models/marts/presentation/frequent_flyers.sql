with passenger_stats as (
    select 
        t.passenger_id,
        t.passenger_name,
        f.departure_airport,
        count(distinct tf.flight_id) as flights_number,
        sum(tf.amount) as purchase_sum
    from {{ ref('tickets') }} t
    join {{ ref('ticket_flights') }} tf on t.ticket_no = tf.ticket_no
    join {{ ref('flights') }} f on tf.flight_id = f.flight_id
    group by t.passenger_id, t.passenger_name, f.departure_airport
),
ranked_airports as (
    select
        passenger_id,
        departure_airport as home_airport,
        flights_number,
        row_number() over (
            partition by passenger_id
            order by flights_number desc, departure_airport asc
        ) as rn
    from passenger_stats
),
final_stats as (
    select 
        ps.passenger_id,
        ps.passenger_name,
        sum(ps.flights_number) as flights_number,
        sum(ps.purchase_sum) as purchase_sum,
        ra.home_airport
    from passenger_stats ps
    join ranked_airports ra on ps.passenger_id = ra.passenger_id and ra.rn = 1
    group by ps.passenger_id, ps.passenger_name, ra.home_airport
),
percentiles as (
    select 
        passenger_id,
        purchase_sum,
        ntile(100) over (order by purchase_sum desc) as percentile
    from final_stats
)

select 
    current_timestamp as created_at,
    fs.passenger_id,
    fs.passenger_name,
    fs.flights_number,
    fs.purchase_sum,
    fs.home_airport,
    case 
        when p.percentile <= 5 then '5'
        when p.percentile <= 10 then '10'
        when p.percentile <= 25 then '25'
        when p.percentile <= 50 then '50'
        else '50+'
    end as customer_group
from final_stats fs
join percentiles p on fs.passenger_id = p.passenger_id
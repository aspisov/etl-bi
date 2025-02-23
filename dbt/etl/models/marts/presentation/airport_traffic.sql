{{
    config(
        unique_key=['flight_date', 'airport_code', 'linked_airport_code']
    )
}}

with daily_traffic as (
    select 
        date(coalesce(f.actual_arrival, f.actual_departure)) as flight_date,
        f.arrival_airport as airport_code,
        f.departure_airport as linked_airport_code,
        count(*) as flights_in,
        0 as flights_out,
        count(distinct bp.ticket_no) as passengers_in,
        0 as passengers_out
    from {{ ref('flights') }} f
    left join {{ ref('boarding_passes') }} bp on f.flight_id = bp.flight_id
    where coalesce(f.actual_arrival, f.actual_departure) is not null
    {% if is_incremental() %}
        and date(coalesce(f.actual_arrival, f.actual_departure)) = current_date - interval '1 day'
    {% endif %}
    group by 1, 2, 3

    union all

    select 
        date(coalesce(f.actual_arrival, f.actual_departure)) as flight_date,
        f.departure_airport as airport_code,
        f.arrival_airport as linked_airport_code,
        0 as flights_in,
        count(*) as flights_out,
        0 as passengers_in,
        count(distinct bp.ticket_no) as passengers_out
    from {{ ref('flights') }} f
    left join {{ ref('boarding_passes') }} bp on f.flight_id = bp.flight_id
    where coalesce(f.actual_arrival, f.actual_departure) is not null
    {% if is_incremental() %}
        and date(coalesce(f.actual_arrival, f.actual_departure)) = current_date - interval '1 day'
    {% endif %}
    group by 1, 2, 3
)

select 
    current_timestamp as created_at,
    flight_date,
    airport_code,
    linked_airport_code,
    sum(flights_in) as flights_in,
    sum(flights_out) as flights_out,
    sum(passengers_in) as passengers_in,
    sum(passengers_out) as passengers_out
from daily_traffic
group by 1, 2, 3, 4
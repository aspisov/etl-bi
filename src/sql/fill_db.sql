-- Insert more airports
INSERT INTO airports (airport_code, airport_name, city, coordinates_lon, coordinates_lat, timezone) VALUES
    ('SVO', 'Sheremetyevo', 'Moscow', 37.4146, 55.9726, 'Europe/Moscow'),
    ('DME', 'Domodedovo', 'Moscow', 37.9062, 55.4103, 'Europe/Moscow'),
    ('LED', 'Pulkovo', 'St. Petersburg', 30.2625, 59.8003, 'Europe/Moscow'),
    ('JFK', 'John F Kennedy', 'New York', -73.7789, 40.6397, 'America/New_York'),
    ('LAX', 'Los Angeles International', 'Los Angeles', -118.4081, 33.9425, 'America/Los_Angeles'),
    ('ORD', 'O''Hare International', 'Chicago', -87.9047, 41.9786, 'America/Chicago');

-- Insert aircrafts
INSERT INTO aircrafts (aircraft_code, model, range) VALUES
    ('773', '{"en": "Boeing 777-300", "ru": "Боинг 777-300"}', 11100),
    ('321', '{"en": "Airbus A321-200", "ru": "Аэробус A321-200"}', 5600),
    ('733', '{"en": "Boeing 737-300", "ru": "Боинг 737-300"}', 4200);

-- Generate bookings and tickets with realistic patterns
DO $$
DECLARE
    passenger_names TEXT[] := ARRAY[
        'John Smith', 'Emma Wilson', 'Michael Brown', 'Sarah Davis', 
        'James Johnson', 'Oliver Taylor', 'Sophie Anderson', 'William White',
        'Elizabeth Martin', 'Alexander Thompson', 'Victoria Moore', 'Thomas Wright'
    ];
    passenger_id TEXT;
    passenger_name TEXT;
    book_ref TEXT;
    ticket_no TEXT;
    i INTEGER;
    j INTEGER;
    num_bookings INTEGER;
BEGIN
    -- Create frequent flyers with multiple bookings
    FOR i IN 1..12 LOOP
        passenger_id := 'PS' || LPAD(i::TEXT, 3, '0');
        passenger_name := passenger_names[i];
        
        -- Each passenger has between 3 and 10 bookings
        num_bookings := (FLOOR(RANDOM() * 7 + 3))::int;
        FOR j IN 1..num_bookings LOOP
            -- Generate a unique booking reference
            book_ref := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));
            
            -- Insert booking with random booking date and total amount
            INSERT INTO bookings (book_ref, book_date, total_amount)
            VALUES (
                book_ref, 
                '2024-01-01'::DATE + (FLOOR(RANDOM() * 30))::INTEGER,
                FLOOR(RANDOM() * 1500 + 500)::NUMERIC
            );
            
            -- Generate a unique ticket number
            ticket_no := LPAD(((i * 100 + j) * 1000)::TEXT, 13, '0');
            
            -- Insert ticket including random contact_data (phone)
            INSERT INTO tickets (ticket_no, book_ref, passenger_id, passenger_name, contact_data)
            VALUES (
                ticket_no, 
                book_ref, 
                passenger_id, 
                passenger_name,
                ('{"phone": "' || LPAD(FLOOR(RANDOM() * 9999999999)::TEXT, 10, '0') || '"}')::JSONB
            );
        END LOOP;
    END LOOP;
END $$;

-- Instead of generating flights with a DO block (which was causing null values for departure_airport),
-- insert one valid flight row manually:
INSERT INTO flights (
    flight_no,
    scheduled_departure,
    scheduled_arrival,
    departure_airport,
    arrival_airport,
    status,
    aircraft_code,
    actual_departure,
    actual_arrival
)
VALUES (
    'FL0001',
    '2024-01-07 16:00:00+00',
    '2024-01-07 19:00:00+00',
    'SVO',
    'JFK',
    'Arrived',
    '321',
    '2024-01-07 16:26:35+00',
    '2024-01-07 19:09:56+00'
);

-- Generate ticket_flights with varying fare conditions and amounts
INSERT INTO ticket_flights (ticket_no, flight_id, fare_conditions, amount)
SELECT 
    t.ticket_no,
    f.flight_id,
    CASE WHEN RANDOM() < 0.2 THEN 'Business' ELSE 'Economy' END AS fare_conditions,
    CASE WHEN RANDOM() < 0.2 
         THEN FLOOR(RANDOM() * 1000 + 1500)::NUMERIC 
         ELSE FLOOR(RANDOM() * 500 + 500)::NUMERIC 
    END AS amount
FROM tickets t
CROSS JOIN flights f
WHERE RANDOM() < 0.1  -- Approximately 10% of available flights per ticket
LIMIT 200;

-- Generate boarding passes for flights that have actual departure data
INSERT INTO boarding_passes (ticket_no, flight_id, boarding_no, seat_no)
SELECT 
    tf.ticket_no,
    tf.flight_id,
    ROW_NUMBER() OVER (PARTITION BY tf.flight_id ORDER BY RANDOM()),
    CASE WHEN tf.fare_conditions = 'Business' 
         THEN (FLOOR(RANDOM() * 5) + 1)::TEXT || CHR(65 + FLOOR(RANDOM() * 2)::INTEGER)
         ELSE (FLOOR(RANDOM() * 20) + 6)::TEXT || CHR(65 + FLOOR(RANDOM() * 6)::INTEGER)
    END AS seat_no
FROM ticket_flights tf
WHERE EXISTS (
    SELECT 1 FROM flights f 
    WHERE f.flight_id = tf.flight_id 
      AND f.actual_departure IS NOT NULL
);
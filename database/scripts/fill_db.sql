-- Insert sample airports
INSERT INTO airports (airport_code, airport_name, city, coordinates_lon, coordinates_lat, timezone) VALUES
('JFK', 'John F Kennedy', 'New York', -73.778889, 40.639722, 'America/New_York'),
('LAX', 'Los Angeles International', 'Los Angeles', -118.408056, 33.942536, 'America/Los_Angeles'),
('ORD', 'O''Hare International', 'Chicago', -87.904724, 41.978611, 'America/Chicago');

-- Insert sample aircraft
INSERT INTO aircrafts (aircraft_code, model, range) VALUES
('773', '{"en": "Boeing 777-300", "ru": "Боинг 777-300"}', 11100),
('321', '{"en": "Airbus A321-200", "ru": "Аэробус A321-200"}', 5600);

-- Insert sample bookings
INSERT INTO bookings (book_ref, book_date, total_amount) VALUES
('ABC123', '2024-01-01', 1000.00),
('DEF456', '2024-01-02', 1500.00),
('GHI789', '2024-01-03', 2000.00);

-- Insert sample tickets
INSERT INTO tickets (ticket_no, book_ref, passenger_id, passenger_name, contact_data) VALUES
('1234567890123', 'ABC123', 'PS001', 'John Doe', '{"phone": "1234567890"}'),
('2345678901234', 'DEF456', 'PS002', 'Jane Smith', '{"phone": "2345678901"}'),
('3456789012345', 'GHI789', 'PS003', 'Bob Johnson', '{"phone": "3456789012"}'),
('4567890123456', 'ABC123', 'PS004', 'Alice Brown', '{"phone": "4567890123"}');

-- Insert sample flights
INSERT INTO flights (flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code) VALUES
('FL0001', '2024-01-01 10:00:00', '2024-01-01 13:00:00', 'JFK', 'LAX', 'Arrived', '773'),
('FL0002', '2024-01-01 14:00:00', '2024-01-01 17:00:00', 'LAX', 'ORD', 'Arrived', '321'),
('FL0003', '2024-01-02 09:00:00', '2024-01-02 12:00:00', 'ORD', 'JFK', 'Arrived', '773'),
('FL0004', '2024-01-02 15:00:00', '2024-01-02 18:00:00', 'JFK', 'LAX', 'Arrived', '321');

-- Insert sample ticket_flights
INSERT INTO ticket_flights (ticket_no, flight_id, fare_conditions, amount) VALUES
('1234567890123', 1, 'Economy', 500.00),
('2345678901234', 2, 'Business', 800.00),
('3456789012345', 3, 'Economy', 600.00),
('4567890123456', 4, 'Economy', 550.00);

-- Insert sample seats for Boeing 777-300
INSERT INTO seats (aircraft_code, seat_no, fare_conditions) VALUES
('773', '1A', 'Business'),
('773', '1B', 'Business'),
('773', '10A', 'Economy'),
('773', '10B', 'Economy'),
('773', '10C', 'Economy');

-- Insert sample seats for Airbus A321-200
INSERT INTO seats (aircraft_code, seat_no, fare_conditions) VALUES
('321', '1A', 'Business'),
('321', '1B', 'Business'),
('321', '15A', 'Economy'),
('321', '15B', 'Economy'),
('321', '15C', 'Economy');

-- Insert sample boarding passes
INSERT INTO boarding_passes (ticket_no, flight_id, boarding_no, seat_no) VALUES
('1234567890123', 1, 1, '10A'),
('2345678901234', 2, 1, '1A'),
('3456789012345', 3, 1, '15B'),
('4567890123456', 4, 1, '15A');
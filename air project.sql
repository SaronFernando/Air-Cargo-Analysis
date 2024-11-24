CREATE TABLE route_details (
    route_id INT PRIMARY KEY, -- Ensures uniqueness for route_id
    flight_num VARCHAR(10) NOT NULL CHECK (flight_num LIKE '[A-Z0-9]%'), -- Check constraint to validate flight number
    origin_airport CHAR(3) NOT NULL, -- IATA codes are typically 3 characters
    destination_airport CHAR(3) NOT NULL,
    aircraft_id INT NOT NULL, -- Assuming aircraft_id is an integer
    distance_miles INT NOT NULL CHECK (distance_miles > 0), -- Check constraint for distance_miles
    UNIQUE (route_id) -- Additional unique constraint on route_id
);
SELECT DISTINCT class_id
FROM passengers_on_flights
WHERE route_id BETWEEN 1 AND 25;
SELECT 
    COUNT(*) AS number_of_passengers, 
    SUM(Price_per_ticket) AS total_revenue 
FROM ticket_details 
WHERE class_id = 'Business';

SELECT 
    CONCAT(first_name, ' ', last_name) AS full_name
FROM customer;
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name
FROM 
    customer c
INNER JOIN 
    ticket_details t ON c.customer_id = t.customer_id;
SELECT 
    c.first_name, 
    c.last_name
FROM 
    customer c
INNER JOIN 
    ticket_details t ON c.customer_id = t.customer_id
WHERE 
    t.brand = 'Emirates';
SELECT 
    customer_id
FROM 
    passengers_on_flights
WHERE 
    class_id = 'Economy Plus'
GROUP BY 
    customer_id
HAVING 
    COUNT(*) > 0;
SELECT 
    IF(SUM(Price_per_ticket) > 10000, 'Revenue Crossed 10000', 'Revenue Below 10000') AS revenue_status
FROM 
    ticket_details;

FLUSH PRIVILEGES;
SELECT 
    class_id, 
    Price_per_ticket, 
    MAX(Price_per_ticket) OVER (PARTITION BY class_id) AS max_ticket_price
FROM 
    ticket_details;
    
SHOW INDEXES FROM passengers_on_flights;
DROP INDEX route_id_new ON passengers_on_flights;

CREATE INDEX route_id_new ON passengers_on_flights(route_id);

SELECT class_id
FROM passengers_on_flights
WHERE route_id = 4;
EXPLAIN SELECT class_id
FROM passengers_on_flights
WHERE route_id = 4;
SELECT 
    class_id, 
    aircraft_id, 
    SUM(Price_per_ticket) AS total_ticket_price
FROM 
    ticket_details
GROUP BY 
    class_id, aircraft_id
WITH ROLLUP;

CREATE VIEW business_class_customers AS 
SELECT 
    c.customer_id, 
    CONCAT(c.first_name, ' ', c.last_name) AS full_name, 
    t.brand AS brand
FROM 
    customer c 
INNER JOIN 
    ticket_details t ON c.customer_id = t.class_id
WHERE 
    t.class_id = 'Business';


DELIMITER $$

CREATE PROCEDURE GetPassengerDetailsBetweenRoutes (IN start_route INT, IN end_route INT)
BEGIN
    -- Check if the table exists
    DECLARE table_exists INT;

    -- Check if the passengers_on_flights table exists
    SELECT COUNT(*) INTO table_exists
    FROM information_schema.tables
    WHERE table_name = 'passengers_on_flights';

    IF table_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Table passengers_on_flights does not exist';
    ELSE
        -- Query to get the details of passengers between the specified routes
        SELECT *
        FROM passengers_on_flights
        WHERE route_id BETWEEN start_route AND end_route;
    END IF;
END $$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE GetLongDistanceRoutes()
BEGIN
    -- Query to fetch routes where traveled distance is more than 2000 miles
    SELECT *
    FROM routes
    WHERE distance_miles > 2000;
END $$

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE GroupFlightDistance()
BEGIN
    -- Query to group distance into three categories: SDT, IDT, LDT
    SELECT 
        flight_id,
        distance_miles,
        CASE
            WHEN distance_miles >= 0 AND distance_miles <= 2000 THEN 'SDT' -- Short Distance Travel
            WHEN distance_miles > 2000 AND distance_miles <= 6500 THEN 'IDT' -- Intermediate Distance Travel
            WHEN distance_miles > 6500 THEN 'LDT' -- Long Distance Travel
            ELSE 'Unknown' -- Catch-all for any unclassified distance
        END AS travel_category
    FROM routes;
END $$
DELIMITER $$

CREATE FUNCTION GetComplimentaryServices(class_id VARCHAR(50)) 
RETURNS VARCHAR(3)
DETERMINISTIC
BEGIN
    DECLARE service_status VARCHAR(3);

    IF class_id IN ('Business', 'Economy Plus') THEN
        SET service_status = 'Yes';
    ELSE
        SET service_status = 'No';
    END IF;

    RETURN service_status;
END $$

DELIMITER ;

DELIMITER ;
DELIMITER $$

CREATE PROCEDURE GetTicketDetailsWithServices()
BEGIN
    -- Query to extract ticket purchase date, customer ID, class ID, and complimentary services
    SELECT 
        ticket_purchase_date, 
        customer_id, 
        class_id,
        GetComplimentaryServices(class_id) AS complimentary_services
    FROM ticket_details;
END $$

DELIMITER ;

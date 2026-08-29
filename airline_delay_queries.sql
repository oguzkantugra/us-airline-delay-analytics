-- ====================================================================
-- US AIRLINE OPERATIONAL PERFORMANCE & DELAY ANALYTICS
-- SQL Scripts for Tableau Data Preparation
-- ====================================================================

-- ----------------------------------------------------------------------------
-- MASTER CLEAN VIEW / BASE DATASET
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS view_clean_flights CASCADE;

CREATE VIEW view_clean_flights AS
SELECT 
    -- 1. Date & Identifiers
    "YEAR" AS year,
    "MONTH" AS month,
    "DAY" AS day,
    "DAY_OF_WEEK" AS day_of_week,
    "AIRLINE" AS airline,
    "FLIGHT_NUMBER" AS flight_number,
    "TAIL_NUMBER" AS tail_number,   
    "ORIGIN_AIRPORT" AS origin_airport,
    "DESTINATION_AIRPORT" AS destination_airport,
    "DISTANCE" AS distance,
    "SCHEDULED_DEPARTURE" AS scheduled_departure,
    "DEPARTURE_TIME" AS departure_time,
    "DEPARTURE_DELAY" AS raw_dep_delay,
    CASE WHEN "DEPARTURE_DELAY" < 0 THEN 0 ELSE "DEPARTURE_DELAY" END AS adj_dep_delay,
    CASE WHEN "DEPARTURE_DELAY" <= 15 THEN 1 ELSE 0 END AS is_on_time_departure,
    "TAXI_OUT" AS taxi_out,
    "WHEELS_OFF" AS wheels_off,
    "SCHEDULED_TIME" AS scheduled_time,
    "ELAPSED_TIME" AS elapsed_time,
    "AIR_TIME" AS air_time,
    "WHEELS_ON" AS wheels_on,
    "TAXI_IN" AS taxi_in,
    "SCHEDULED_ARRIVAL" AS scheduled_arrival,
    "ARRIVAL_TIME" AS arrival_time,
    "ARRIVAL_DELAY" AS raw_arr_delay,
    CASE WHEN "ARRIVAL_DELAY" < 0 THEN 0 ELSE "ARRIVAL_DELAY" END AS adj_arr_delay,
    CASE WHEN "ARRIVAL_DELAY" <= 15 THEN 1 ELSE 0 END AS is_on_time_arrival,
    "DIVERTED" AS diverted,
    "CANCELLED" AS cancelled,
    "CANCELLATION_REASON" AS cancellation_reason,
    COALESCE("AIR_SYSTEM_DELAY", 0) AS air_system_delay,
    COALESCE("SECURITY_DELAY", 0) AS security_delay,
    COALESCE("AIRLINE_DELAY", 0) AS airline_delay,
    COALESCE("LATE_AIRCRAFT_DELAY", 0) AS late_aircraft_delay,
    COALESCE("WEATHER_DELAY", 0) AS weather_delay
FROM flights;
-- ----------------------------------------------------------------------------
-- ANALYSIS 1: AIRLINE ON-TIME PERFORMANCE (OTP) BENCHMARKING
-- ----------------------------------------------------------------------------
SELECT 
    airline,
    COUNT(*) AS total_flights,
    ROUND(AVG(is_on_time_departure) * 100, 2) AS otp_rate_pct,
    ROUND(AVG(adj_dep_delay), 2) AS avg_departure_delay_mins,
    ROUND(AVG(cancelled) * 100, 2) AS cancellation_rate_pct
FROM view_clean_flights
WHERE cancelled = 0 AND diverted = 0
GROUP BY airline
ORDER BY otp_rate_pct DESC;

-- -- ----------------------------------------------------------------------------
-- ANALYSIS 2: DELAY ROOT-CAUSE BREAKDOWN BY AIRLINE
-- ----------------------------------------------------------------------------
WITH delay_summary AS (
    SELECT 
        airline,
        COUNT(*) AS delayed_flights_count,
        SUM(airline_delay) AS total_carrier_delay,
        SUM(weather_delay) AS total_weather_delay,
        SUM(air_system_delay) AS total_nas_delay,
        SUM(security_delay) AS total_security_delay,
        SUM(late_aircraft_delay) AS total_late_aircraft_delay,
        -- Total minutes of all kinds of delays:
        SUM(airline_delay + weather_delay + air_system_delay + security_delay + late_aircraft_delay) AS total_delay_mins
    FROM view_clean_flights
    WHERE cancelled = 0 AND diverted = 0
      -- Only ones which have a delay reason (at least 15 minutes of delay):
      AND (airline_delay > 0 OR weather_delay > 0 OR air_system_delay > 0 OR security_delay > 0 OR late_aircraft_delay > 0)
    GROUP BY airline
)
SELECT 
    airline,
    delayed_flights_count,
    total_delay_mins,
    -- Pct of every reason of delay(%):
    ROUND((total_carrier_delay / total_delay_mins::numeric) * 100, 2) AS carrier_delay_pct,
    ROUND((total_late_aircraft_delay / total_delay_mins::numeric) * 100, 2) AS late_aircraft_delay_pct,
    ROUND((total_nas_delay / total_delay_mins::numeric) * 100, 2) AS nas_system_delay_pct,
    ROUND((total_weather_delay / total_delay_mins::numeric) * 100, 2) AS weather_delay_pct,
    ROUND((total_security_delay / total_delay_mins::numeric) * 100, 2) AS security_delay_pct
FROM delay_summary
ORDER BY total_delay_mins DESC;

-- ============================================================================
-- ANALYSIS 3: AIRPORT GROUND BOTTLENECK & TAXI-OUT DURATION ANALYSIS
-- ============================================================================

SELECT 
    origin_airport,
    COUNT(*) AS total_departures,
    ROUND(AVG(taxi_out), 2) AS avg_taxi_out_mins,
    ROUND(AVG(adj_dep_delay), 2) AS avg_departure_delay_mins
FROM view_clean_flights
WHERE cancelled = 0 AND diverted = 0
GROUP BY origin_airport
HAVING COUNT(*) >= 1000
ORDER BY avg_taxi_out_mins DESC
LIMIT 10;

-- ============================================================================
-- ANALYSIS 4: AIRLINE RECOVERY CAPACITY (AIRBORNE DELAY ABSORPTION ANALYSIS)
-- ============================================================================

-- Business Logic:
-- Evaluates flight operations efficiency by measuring whether pilots/airlines 
-- make up time in the air (recovery) or lose more time between departure and arrival.
-- Metrics:
-- 1. delay_difference = arrival_delay - departure_delay
--    (< 0: flight made up time in the air, > 0: flight lost additional time in the air)
-- 2. recovery_rate_pct = percentage of initially delayed flights that reduced delay in air.

WITH delayed_departures AS (
    SELECT 
        airline,
        raw_dep_delay,
        raw_arr_delay,
        (raw_arr_delay - raw_dep_delay) AS air_time_delay_delta,
        CASE 
            WHEN (raw_arr_delay - raw_dep_delay) < 0 THEN 1 
            ELSE 0 
        END AS is_recovered
    FROM view_clean_flights
    WHERE cancelled = 0 
      AND diverted = 0
      AND raw_dep_delay > 15 -- Analyzes flights that started with an operational delay
)
SELECT 
    airline,
    COUNT(*) AS total_delayed_departures,
    ROUND(AVG(raw_dep_delay), 2) AS avg_initial_dep_delay_mins,
    ROUND(AVG(raw_arr_delay), 2) AS avg_final_arr_delay_mins,
    ROUND(AVG(air_time_delay_delta), 2) AS avg_net_airborne_change_mins,
    ROUND(AVG(is_recovered) * 100, 2) AS airborne_recovery_rate_pct
FROM delayed_departures
GROUP BY airline
HAVING COUNT(*) >= 500
ORDER BY airborne_recovery_rate_pct DESC;

-- ============================================================================
-- ANALYSIS 5: DEPARTURE TIME WINDOW & HOURLY CONGESTION ANALYSIS
-- ============================================================================

-- Business Logic:
-- Categorizes scheduled departure times into operational blocks across the day.
-- Tracks how delay risk and cancellation volume compound from early morning
-- to late night (domino / cascading delay effect).

WITH flight_time_blocks AS (
    SELECT 
        airline,
        scheduled_departure,
        adj_dep_delay,
        is_on_time_departure,
        cancelled,
        -- Extract hour from HHMM / integer format (e.g., 630 -> 6, 1745 -> 17)
        FLOOR(scheduled_departure / 100) AS departure_hour,
        CASE 
            WHEN FLOOR(scheduled_departure / 100) BETWEEN 5 AND 8 THEN '1. Early Morning (05-08)'
            WHEN FLOOR(scheduled_departure / 100) BETWEEN 9 AND 12 THEN '2. Morning (09-12)'
            WHEN FLOOR(scheduled_departure / 100) BETWEEN 13 AND 16 THEN '3. Afternoon (13-16)'
            WHEN FLOOR(scheduled_departure / 100) BETWEEN 17 AND 20 THEN '4. Evening (17-20)'
            WHEN FLOOR(scheduled_departure / 100) BETWEEN 21 AND 23 THEN '5. Night (21-23)'
            ELSE '6. Overnight (00-04)'
        END AS time_window
    FROM view_clean_flights
)
SELECT 
    time_window,
    COUNT(*) AS total_flights,
    ROUND(AVG(is_on_time_departure) * 100, 2) AS otp_pct,
    ROUND(AVG(adj_dep_delay), 2) AS avg_delay_mins,
    SUM(cancelled) AS total_cancellations,
    ROUND(AVG(cancelled) * 100, 2) AS cancellation_rate_pct
FROM flight_time_blocks
GROUP BY time_window
ORDER BY time_window;


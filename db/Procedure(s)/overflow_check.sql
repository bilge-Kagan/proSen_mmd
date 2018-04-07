-- When adding new measurement to "measurements" table, overflows
-- are checked according to bounds in "bounds" table. If there is
-- overflow then add the record to "overflows" table.
CREATE PROCEDURE overflow_check (sens_id BIGINT, temp FLOAT(7,3), hum FLOAT(7,3), r_time DATETIME)
  BEGIN
    DECLARE temp_bound FLOAT(7,3);
    DECLARE hum_bound FLOAT(7,3);

    -- Assign variables:
    SELECT temperature_bound, humidity_bound
      INTO temp_bound, hum_bound
    FROM bounds WHERE sensor_id = sens_id;
    -- -- --

    -- Compare record between bounds and add overflow if needed:
    IF (temp > temp_bound) OR (hum > hum_bound) THEN
      INSERT INTO overflows(sensor_id, temperature, humidity, record_time)
        VALUES (sens_id, temp, hum, r_time);
    END IF;
    -- -- --
  END;

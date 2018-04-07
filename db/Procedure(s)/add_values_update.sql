-- When adding new measurement to "measurements" table, last values in
-- "sensors" table must be updated. And then, "statistics" table must be updated according
-- to new values.
CREATE PROCEDURE add_values_update (sens_id BIGINT, temp FLOAT(7,3), hum FLOAT(7,3), r_time DATETIME)
  BEGIN
    DECLARE stats_min_temp FLOAT(7,3);
    DECLARE stats_max_temp FLOAT(7,3);
    DECLARE stats_min_hum FLOAT(7,3);
    DECLARE stats_max_hum FLOAT(7,3);

    DECLARE stats_mean_hum FLOAT(7,3);
    DECLARE stats_mean_temp FLOAT(7,3);
    DECLARE stats_measure_num INT;

    -- Assign variables:
    SELECT min_temperature, min_humidity, max_temperature, max_humidity,
           mean_humidity, mean_temperature,measurement_number
    INTO stats_min_temp, stats_min_hum, stats_max_temp, stats_max_hum,
         stats_mean_hum, stats_mean_temp, stats_measure_num
    FROM statistics
    WHERE sensor_id = sens_id;
    -- -- --

    -- Update "sensors" table:
    UPDATE sensors
      SET last_temperature = temp, last_humidity = hum, last_record_time = r_time
    WHERE id = sens_id;
    -- -- --

    -- Calculate "statistics" mean-values:
    IF (stats_mean_temp IS NULL) THEN
      SELECT AVG(temperature) INTO stats_mean_temp FROM measurements
        WHERE sensor_id = sens_id;
    ELSE
      SET stats_mean_temp = ((stats_mean_temp * stats_measure_num) + temp) / (stats_measure_num + 1);
    END IF;

    IF (stats_mean_hum IS NULL) THEN
      SELECT AVG(humidity) INTO stats_mean_hum FROM measurements
      WHERE sensor_id = sens_id;
    ELSE
      SET stats_mean_hum = ((stats_mean_hum * stats_measure_num) + hum) / (stats_measure_num + 1);
    END IF;
    -- -- --

    -- Control "statistic" max/min-values:
    IF((stats_min_temp IS NULL) OR (temp < stats_min_temp)) THEN SET stats_min_temp = temp; END IF;
    IF((stats_max_temp IS NULL) OR (temp > stats_max_temp)) THEN SET stats_max_temp = temp; END IF;

    IF((stats_min_hum IS NULL) OR (hum < stats_min_hum)) THEN SET stats_min_hum = hum; END IF;
    IF((stats_max_hum IS NULL) OR (hum > stats_max_hum)) THEN  SET stats_max_hum = hum; END IF;
    -- -- --

    -- Increment the measurement_number:
    SET stats_measure_num = stats_measure_num + 1;
    -- -- --

    -- Update "statistics" table;
    UPDATE statistics
      SET measurement_number = stats_measure_num, max_temperature = stats_max_temp, max_humidity = stats_max_hum,
          min_temperature = stats_min_temp, min_humidity = stats_min_hum, mean_temperature = stats_mean_temp,
          mean_humidity = stats_mean_hum
    WHERE sensor_id = sens_id;
    -- -- --
  END;
-- -- --

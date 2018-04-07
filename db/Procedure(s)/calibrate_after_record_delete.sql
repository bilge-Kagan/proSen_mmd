-- After delete records from measurements table; "sensors" and "statistics"
-- tables must be calibrated according to remaining records:
CREATE PROCEDURE calibrate_after_record_delete ()
  BEGIN
    DECLARE sens_id BIGINT;
    DECLARE last_temp FLOAT(7,3);
    DECLARE last_hum FLOAT(7,3);
    DECLARE last_rec_time DATETIME;

    DECLARE measurement_num INTEGER;
    DECLARE max_temp FLOAT(7,3);
    DECLARE max_hum FLOAT(7,3);
    DECLARE min_temp FLOAT(7,3);
    DECLARE min_hum FLOAT(7,3);
    DECLARE mean_temp FLOAT(7,3);
    DECLARE mean_hum FLOAT(7,3);
    -- Declare exit flag from loop:
    DECLARE exit_flag BOOLEAN;
    -- Declare cursor for 'sensors' table:
    DECLARE sensors_cursor CURSOR FOR
      SELECT id FROM sensors;
    -- Set handler "exit_flag = TRUE" when cursor is ended:
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET exit_flag = TRUE;
    -- -- --

    -- Set "exit_flag" to FALSE:
    SET exit_flag = FALSE;
    -- Open cursor:
    OPEN sensors_cursor;
    -- Start Loop:
    calibre: LOOP
      -- Fetch 'sensor_id' from "sensors" table:
      FETCH sensors_cursor INTO sens_id;
      -- -- --

      -- Control 'exit_flag' handler:
      IF exit_flag THEN
        CLOSE sensors_cursor;
        LEAVE calibre;
        -- -- --
        -- ELSE:
      ELSE
        -- "sensors" table & "statatistics" table=> Get last measurement and
        -- statistical values if any records belong related sensor_id:
        IF(SELECT EXISTS(SELECT id FROM measurements WHERE sens_id = measurements.sensor_id LIMIT 1)) THEN

          -- SensorsTable:
          SELECT temperature, humidity, record_time INTO last_temp, last_hum, last_rec_time
          FROM measurements WHERE sensor_id = sens_id ORDER BY record_time DESC LIMIT 1;
          -- -- --
          -- Update "sensors" table:
          UPDATE sensors
            SET last_temperature = last_temp, last_humidity = last_hum, last_record_time = last_rec_time
          WHERE id = sens_id;
          -- -- --

          -- StatisticsTable:
          SELECT COUNT(id), MAX(temperature), MAX(humidity), MIN(temperature),
            MIN(humidity), AVG(temperature), AVG(humidity) INTO measurement_num, max_temp,
            max_hum, min_temp, min_hum, mean_temp, mean_hum FROM measurements
          WHERE sensor_id = sens_id;
          -- -- --
          -- Update "statistics" table:
          UPDATE statistics
            SET measurement_number = measurement_num, max_temperature = max_temp,
              max_humidity = max_hum, min_temperature = min_temp, min_humidity = min_hum,
              mean_temperature = mean_temp, mean_humidity = mean_hum
          WHERE sensor_id = sens_id;
          -- -- --

        ELSE
          -- If there is no record related with sensor, assign default values:

          -- "sensors" table:
          UPDATE sensors
            SET last_temperature = 0.0, last_humidity = 0.0, last_record_time = FROM_UNIXTIME(0)
          WHERE id = sens_id;
          -- -- --

          -- "statistics" table:
          UPDATE statistics
          SET measurement_number = 0, max_temperature = 0.0,
            max_humidity = 0.0, min_temperature = 0.0, min_humidity = 0.0,
            mean_temperature = 0.0, mean_humidity = 0.0
          WHERE sensor_id = sens_id;
        END IF;
        -- -- --

      END IF;
    END LOOP calibre;
  END;
-- -- --

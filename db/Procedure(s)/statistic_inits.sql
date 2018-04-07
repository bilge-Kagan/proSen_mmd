-- When new sensor name is added to "sensors" table, new statistic account
-- must be open on "statistics" table, related with new sensor's id.
CREATE PROCEDURE statistic_init(sens_id BIGINT)
  BEGIN
    INSERT INTO statistics(sensor_id)
      VALUES (sens_id);
  END;

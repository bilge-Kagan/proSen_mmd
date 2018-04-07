-- When new sensor name is added to "sensors" table, new bound account
-- must be opened on "bounds" table, related with new sensor's id:
CREATE PROCEDURE bound_init(sens_id BIGINT)
  BEGIN
    INSERT INTO bounds(sensor_id, created_at, updated_at)
      VALUES (sens_id, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());
  END;

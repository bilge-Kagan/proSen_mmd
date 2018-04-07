-- When adding new sensor into "sensors" table, <statistic_inits> procedure
-- must be called.
CREATE TRIGGER add_sensor AFTER INSERT ON sensors
  FOR EACH ROW
  BEGIN
    CALL statistic_init(NEW.id);
    CALL bound_init(NEW.id);
  END;

-- When measurement record is added, the "add_values_update" procedure will been triggered.
CREATE TRIGGER add_record AFTER INSERT ON measurements
  FOR EACH ROW
  BEGIN
    CALL add_values_update(NEW.sensor_id, NEW.temperature, NEW.humidity, NEW.record_time);
    CALL overflow_check(NEW.sensor_id, NEW.temperature, NEW.humidity, NEW.record_time);
  END;

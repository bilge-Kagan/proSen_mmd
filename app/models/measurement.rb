class Measurement < ApplicationRecord
  belongs_to :sensor
  # If sensor is not valid, then measurement record
  # is not valid also!..
  validates_associated :sensor

  # Method to delete records from "measurements" table:
  def self.calibrate_filtered_delete
    # After records deleting; statistics, overflows and sensors tables must
    # be updated. To do this, "MySQL procedure" is used.
    ActiveRecord::Base.connection.execute('CALL calibrate_after_record_delete')
  rescue StandardError => error
    puts error.inspect + ' #after_record_delete_process@Measurement'
    false
  end
  # #

  # Method to retrieve records which measured last an hour:
  def self.measured_last_hour
    # Return data:
    # [['sensor_1', temperature, humidity],
    #  ['sensor_2', temperature, humidity],
    # ..]
    Measurement
      .joins('INNER JOIN sensors ON sensors.id = measurements.sensor_id')
      .where('measurements.record_time > ?', Time.now - (60 * 60))
      .pluck('sensors.name', 'measurements.temperature',
             'measurements.humidity')
    # Rescue of method is inside its used method:
    # <CheckpointClass : records_in_last_hour>
  end
  # #

end
# # # #

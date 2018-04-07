class Sensor < ApplicationRecord
  has_one :statistic
  has_one :bound
  has_many :measurements
  has_many :overflows
  # Validation of sensor name when adding to database:
  validates :name, presence: true

  # Method to retrieve last measurements:
  def self.last_records_get
    # This method returns an ActiveRecord::Result
    Sensor.connection.select_all('select name, last_temperature,
           last_humidity, last_record_time from sensors')
  end
  # #

  # Method to delete sensor from "sensors" table and
  # all related tables:
  def self.safe_remove(sens_id)
    # First remove from "measurements":
    Measurement.where('sensor_id = ?', sens_id).delete_all
    # After that, remove from "overflows":
    Overflow.where('sensor_id = ?', sens_id).delete_all
    # After, remove from "bounds":
    Bound.where('sensor_id = ?', sens_id).delete_all
    # Then, remove from "statistics":
    Statistic.where('sensor_id = ?', sens_id).delete_all
    # Finally, remove from "sensors":
    Sensor.delete(sens_id)
    # Return true:
    true

  rescue StandardError => error
    p error.message
    false
  end
  # #
end

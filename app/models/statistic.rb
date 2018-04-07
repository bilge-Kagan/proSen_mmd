class Statistic < ApplicationRecord
  belongs_to :sensor

  # Method to get statatistics:
  def self.statistics_get
    # This method returns an ActiveRecord::Result
    Statistic.connection.select_all('select sensors.name as name,
       measurement_number, max_temperature, max_humidity, min_temperature,
       min_humidity, mean_temperature,
       mean_humidity from statistics inner join
       sensors on statistics.sensor_id = sensors.id')
  end
  # #

end

# Class to manage all records belongs each sensor:
class RecordManagement
  # Accessors:
  attr_reader :sens_name, :coefficient_limit, :records_amount,
              :part_coefficient

  # Method to initialize instance variables:
  def initialize(sens_name)
    @sens_name = sens_name.to_s
    @sens_id = fetch_sensor_id
    @row_limit = 500
    @records_amount = fetch_recs_amount
    @part_coefficient = 0
    @coefficient_limit = @records_amount / @row_limit
    @offset = 0
  end
  # #

  # Method to get records:
  def records_get(part)
    raise ArgumentError, 'Invalid page number!' unless
        part >= 0 && part <= @coefficient_limit
    fetch_records(part)
  rescue StandardError => error
    puts error.message + ' #records_get@RecordManagement'
    false
  end
  # #

  # Method to remove records, remove all "Sensor":
  def del_all_sensor_recs
    Sensor.safe_remove(@sens_id)
  end
  # #

  # Method to exract filtered data as 'csv':
  def exract_as_csv
    # All records of sensor as ActiveRecord_Relation:
    recs = fetch_all_records
    # Generate CSV data:
    CSV.generate(write_headers: true, headers: %w[temperature
                                                  humidity
                                                  record_time]) do |csv|
      recs.each do |dat|
        csv << [dat.temperature, dat.humidity, dat.record_time]
      end
    end
  end
  # #

  # Private methods:

  private

  # Method to check sensor name and get sensor id
  # on initializing:
  def fetch_sensor_id
    raise NameError, 'Sensor name CAN NOT found!' unless
        Sensor.where('name = ?', @sens_name).exists?
    # Return sensro_id:
    Sensor.find_by_name(sens_name).id
  end
  # #

  # Method to get records amount:
  def fetch_recs_amount
    Statistic.find_by_sensor_id(@sens_id).measurement_number
  end
  # #

  # Method to fetch records for related "@part_coefficient":
  def fetch_records(part)
    @part_coefficient = part
    @offset = @part_coefficient * @row_limit
    # Fetch records as array including hashs:
    Measurement.where('sensor_id = ?', @sens_id).offset(@offset)
               .limit(@row_limit).map do |elm|
      { temperature: elm.temperature, humidity: elm.humidity,
        record_time: elm.record_time }
    end
  end
  # #

  # Method to get all records:
  def fetch_all_records
    Measurement.where('sensor_id = ?', @sens_id)
  end
  # #
end
# # # #

# Class to filtering and organizing records:
class RecordFiltering
  # Accessors:
  attr_accessor :part_coefficient
  attr_reader :total_row_count, :coefficient_limit

  # Constant:
  CONDITION_STRING = '(sensor_id IN (?) AND '\
'(temperature BETWEEN ? AND ?) AND (humidity BETWEEN ? AND ?) AND '\
'(record_time BETWEEN ? AND ?))'.freeze

  # Method to initialize instance variables:
  def initialize
    # "@filter_args" => filtering arguments hash
    # "@part_coefficient => Records page number, starting at 0"
    # "@total_row_count => Total rows count of filtered records"
    # "@offset => Records offset row"
    # "@row_limit => Maximum row count which fetching at a time"
    # "@sensor_ids => Hash contain sensor ids and related sensor names
    # in @filter_args"
    # "@coefficient_limit => Maximum page number division of filtered records."
    @filter_args = {}
    @sensor_ids = {}
    @part_coefficient = 0
    @total_row_count = 0
    @offset = 0
    @coefficient_limit = 0
    # Max row count which loaded page every query:
    @row_limit = 500
  end
  # #

  # Method to assign new values according to filter parameters:
  # "@filter_args" - "@sensor_ids"
  # "@total_row_count" - "@coefficient_limit"
  def assign_filter_params(parameter)
    # Parameter is HASH.
    @filter_args = parameter.is_a?(Hash) ? parameter : {}
    # After assignment of filter paramater, initialize some variables
    # related with filter arguments.
    init_variables
  end
  # #

  # Method to get filtered records:
  def fetch_filtered_records(part)
    raise ArgumentError, 'Invalid page number!' unless
        part >= 0 && part <= @coefficient_limit
    records_getting(part)
  rescue StandardError => error
    puts error.inspect + ' #fetch_filtered_records@RecordFiltering'
    false
  end
  # #

  # Method to delete filtered records:
  def remove_filtered_records
    # Delete filtered records, queried by "@filter_args":
    Measurement.where(CONDITION_STRING,
                      @sensor_ids.keys, @filter_args['min_temp'],
                      @filter_args['max_temp'], @filter_args['min_hum'],
                      @filter_args['max_hum'], @filter_args['min_date'],
                      @filter_args['max_date']).delete_all
    # Now calibrate "sensors" and "statistics" tables:
    Measurement.calibrate_filtered_delete
  end
  # #

  # Method to exract filtered data as 'csv':
  def exract_as_csv
    # All filtered records as array contains hashes:
    recs = records_get_all
    # Generate CSV data:
    CSV.generate(write_headers: true, headers: %w[sensor_name
                                                  temperature humidity
                                                  record_time]) do |csv|
      recs.each do |dat|
        csv << [@sensor_ids[dat.sensor_id], dat.temperature, dat.humidity,
                dat.record_time]
      end
    end
  end
  # #

  # Private methods:

  private

  # Method to assign initialized variables for new values
  # according to filtering:
  def init_variables
    # Get sensor's ids for sensor names as hash:
    Sensor.where('name IN (?)', @filter_args['sensor_name']).each do |el|
      @sensor_ids[el.id] = el.name
    end

    # Get total row count for filtering result:
    @total_row_count = Measurement
                       .where(CONDITION_STRING,
                              @sensor_ids.keys, @filter_args['min_temp'],
                              @filter_args['max_temp'], @filter_args['min_hum'],
                              @filter_args['max_hum'], @filter_args['min_date'],
                              @filter_args['max_date']).count
    # Calculate coefficient limit, other name 'page count':
    @coefficient_limit = @total_row_count / @row_limit
  end
  # #

  # Method to get filtered records as array contains hashes:
  def records_getting(part)
    @part_coefficient = part
    @offset = @part_coefficient * @row_limit
    # Create array include hashes which each other include a filtered record.
    Measurement.where(CONDITION_STRING,
                      @sensor_ids.keys, @filter_args['min_temp'],
                      @filter_args['max_temp'], @filter_args['min_hum'],
                      @filter_args['max_hum'], @filter_args['min_date'],
                      @filter_args['max_date']).offset(@offset)
               .limit(@row_limit).map do |elm|
      { sensor_name: @sensor_ids[elm.sensor_id], temperature: elm.temperature,
        humidity: elm.humidity, record_time: elm.record_time }
    end
  end
  # #

  # Method to get all filtered records as ActiveRecord_Relation:
  def records_get_all
    Measurement.where(CONDITION_STRING,
                      @sensor_ids.keys, @filter_args['min_temp'],
                      @filter_args['max_temp'], @filter_args['min_hum'],
                      @filter_args['max_hum'], @filter_args['min_date'],
                      @filter_args['max_date'])
  end
  # #
end
# # # #

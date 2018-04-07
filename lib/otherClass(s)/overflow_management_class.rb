# Class to manage overflow records for each sensors:
class OverflowManagement
  # Accessors:
  attr_reader :sensors

  # Method to initialize instance variables:
  def initialize
    @row_limit = 50
    @sens_structure = build_sens_structure
    # Setup structure:
    structure_init
    # Sensor names:
    @sensors = @sens_structure.keys
  end

  # Method to get overflow records of related sensor
  # for next part:
  def fetch_one_part(sensor_name)
    # Call private method to fetch:
    fetch_overflow(sensor_name.to_s)
  end
  # #

  # Method to remove overflow records, which between given dates:
  def remove_overflows(sensor_name, min_date, max_date)
    del_overflows(sensor_name.to_s, min_date, max_date)
  end
  # #

  # Private methods:

  private

  # Method to create sensor structure:
  def build_sens_structure
    wrapper = {}
    # Get sensors name and id:
    sens_name_id = Sensor.all.map do |item|
      { name: item.name, id: item.id }
    end
    # Buil main structure hash:
    sens_name_id.each do |elm|
      wrapper[elm[:name].to_s] = { id: elm[:id], records_amount: 0,
                                   coefficient_limit: 0, part_coefficient: 0,
                                   offset: 0 }
    end
    # Return the wrapper:
    wrapper
  end
  # #

  # Method to initialize main structure:
  def structure_init
    @sens_structure.each_value do |properties|
      # Fetch amount of records related the sensor:
      properties[:records_amount] = Overflow
                                    .where('sensor_id = ?', properties[:id])
                                    .count
      # Initialize coefficient limit:
      properties[:coefficient_limit] = properties[:records_amount] / @row_limit
    end
  end
  # #

  # Method to fetch overflow records:
  def fetch_overflow(sens_name)
    # Chack part validity:
    return false unless part_valid?(sens_name)
    # Create return hash:
    rt_hash = { recs: [], cont: false }
    rt_hash[:recs] = overflow_query(sens_name)
    # Increase the "part_coefficient" of sensor:
    @sens_structure[sens_name][:part_coefficient] += 1
    # Set offset:
    @sens_structure[sens_name][:offset] =
      @sens_structure[sens_name][:part_coefficient] * @row_limit
    rt_hash[:cont] = part_continuity?(sens_name)
    rt_hash
  rescue StandardError => error
    puts error.inspect + ' #fetch_overflow@OverflowManagement'
    false
  end
  # #

  # Method to query for overflow records and return
  # them as array contains hashes:
  def overflow_query(sensor_name)
    Overflow.where('sensor_id = ?',
                   @sens_structure[sensor_name][:id])
            .offset(@sens_structure[sensor_name][:offset])
            .limit(@row_limit).map do |item|
      { temperature: item.temperature, humidity: item.humidity,
        record_time: item.record_time }
    end
  rescue StandardError => error
    puts error.inspect + ' #overflow_query@OverflowManagement'
    []
  end
  # #

  # Method to check "part_coefficient" validity in <fetch_overflow>:
  def part_valid?(sensor_name)
    (@sens_structure[sensor_name][:part_coefficient] >= 0) &&
      (@sens_structure[sensor_name][:part_coefficient] <=
      @sens_structure[sensor_name][:coefficient_limit])
  rescue StandardError => error
    puts error.inspect + ' #part_valid?@OverflowManagement'
    false
  end
  # #

  # Method to set continuity value of part number in <fetch_overflow>:
  def part_continuity?(sensor_name)
    @sens_structure[sensor_name.to_s][:part_coefficient] <=
      @sens_structure[sensor_name.to_s][:coefficient_limit]
  end

  # Method to delete overflow records for related sensor:
  def del_overflows(sensor_name, min_date, max_date)
    return false unless @sens_structure.key?(sensor_name)
    # Delete query:
    Overflow.where('(sensor_id = ?) AND (record_time BETWEEN ? AND ?)',
                   @sens_structure[sensor_name][:id], min_date, max_date)
            .delete_all
    # Calibrate:
    calibrate_after_del(sensor_name)
  rescue StandardError => error
    puts error.inspect + ' #del_overflow@OverflowManagement'
    false
  end
  # #

  # Method to calibrate after delete records:
  def calibrate_after_del(sensor_name)
    # Find and assign count of records related with sensor_name:
    @sens_structure[sensor_name][:records_amount] =  Overflow
                                                     .where('sensor_id = ?',
                                                            properties[:id])
                                                     .count
    # Set coefficient_limit:
    @sens_structure[sensor_name][:coefficient_limit] =
      (@sens_structure[sensor_name][:records_amount] / @row_limit).ceil - 1
    # Set offset and part_coefficient:
    @sens_structure[sensor_name][:offset] = 0
    @sens_structure[sensor_name][:part_coefficient] = 0
  end
  # #
end
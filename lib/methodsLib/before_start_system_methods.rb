# Method to assign global errors($initialize_error):
def initializing_error(index, error)
  $initialize_error[0] = index
  $initialize_error[index] = error
  index
end
# #

# Method to check the master ip file and slaves ip file is there in
# configuration directory:
def check_config_files
  unless File.exist?(IP_PATH + 'master_ip.json') &&
         File.exist?(IP_PATH + 'slaves_ip.json')
    initializing_error(2, 'Configuration files NOT found!')
    return false
  end
  true
end
# #

# Method to create device start settings from configuration files:
def start_settings_init
  $device_start_settings['master'] = master_ip_get
  $device_start_settings['slaves'] = read_slaves_ip.values
  $device_start_settings['interval'] = $device_interval_time
end
# #

# Method to check master device's IP and slaves device's IPs:
def init_and_check_ips
  start_settings_init
  raise 'You have to set master device!' if $device_start_settings['master'].empty?
  raise 'You have to set least one slave device!' if $device_start_settings['slaves'].empty?
  true
rescue StandardError => error
  initializing_error(4, error.inspect + ' #init_and_check_ips')
  false
end
# #

# Method to combine raise condition on <device_pin_reading> method:
def combine_raises(slave_ip)
  raise "Device@#{slave_ip} PIN file Expected!" unless File.exist?(IP_PATH + "#{slave_ip}.json")
  slave_pins = JSON.parse(File.read(IP_PATH + "#{slave_ip}.json"))
  raise "Device@#{slave_ip} PIN file is broken!" unless slave_pins.is_a?Array
  raise "Device@#{slave_ip} have NOT selected PIN" if slave_pins.empty?
  $device_start_settings[slave_ip] = slave_pins.sort!
end
# #

# Method to read and assings devices PINs from pin files:
def device_pin_reading
  $device_start_settings['slaves'].each do |slave_ip|
    combine_raises(slave_ip.to_s)
  end
  true
rescue StandardError => error
  initializing_error(3,
                     error.inspect + ' #device_pin_reading@PrepareStartPackage')
  false
end
# #

# Method to set the start package:
def set_start_package
  package_array = []
  package_array << 'interval'
  package_array << $device_interval_time
  package_array << 'master_ip'
  package_array << $device_start_settings['master'][0].to_s
  package_array << 'slave_count'
  package_array << $device_start_settings['slaves'].count
  package_array
end
# #

# Method to create PIN array part of start package:
def create_pin_array(slaves_ip, package)
  slaves_ip.each_with_index do |ip, index|
    temp_array = []
    temp_array << "Slave##{index + 1}"
    temp_array << ip
    temp_array << 'pins count'
    temp_array << $device_start_settings[ip.to_s].count
    temp_array << $device_start_settings[ip.to_s]
    package << temp_array
  end
end
# #

# !! Bounds are stored in SQL.
# # Method to add device's PINs to "$sensor_bounds" hash:
# def add_pins_to_sensor_bounds(slaves_ip)
#   slaves_ip.each_with_index do |ip, index|
#     $device_start_settings[ip.to_s].each do |pn|
#       $sensor_bounds[index.to_s + '@' + pn.to_s] = []
#     end
#   end
# end
# #

# Method to save start package to file:
def save_start_package(package)
  package_file = File.open(IP_PATH + 'start_package.json', 'w+')
  package_file.write(package.to_json)
  package_file.close
end
# #

# Method to prepare of start package:
def prepare_start_package
  # Check config files:
  # Initialize device IPs and interval to "$device_start_settings"
  # and check them:
  # Check PIN files and initialize device's PINs:
  return nil unless check_config_files && init_and_check_ips && device_pin_reading
  # Create start package:
  start_package = set_start_package
  # Add pin array to the start package:
  create_pin_array($device_start_settings['slaves'], start_package)

  # !! Bounds are stored in SQL.
  # Add PINs name to "$sensor_bounds" has as a key and assign them empty array:
  # add_pins_to_sensor_bounds($device_start_settings['slaves'])

  # Save start package to the file:
  save_start_package(start_package)
  # Return start package:
  start_package
end
# #

# Method to get current settings:
def current_saved_settings
  settings = {}
  settings['interval'] = $device_interval_time
  settings['master'] = master_ip_get
  settings['slaves'] = read_slaves_ip.values
  settings['slaves'].each do |slave_ip|
    if File.exist?(IP_PATH + "#{slave_ip}.json")
      settings[slave_ip.to_s] = JSON.parse(File.read(IP_PATH + "#{slave_ip}.json"))
    else
      settings = {}
    end
  end
  settings
rescue StandardError => error
  puts error.inspect + ' #current_saved_settings'
  {}
end
# #

# Method to request to propagator for getting config if there:
def config_request(ip, port)
  propagator_connection = TCPSocket.new(ip, port)
  propagator_connection.print('"getConfig"')
  Timeout.timeout(2) { propagator_connection.gets }
rescue StandardError => error
  initializing_error(9,
                     error.inspect + ' #propagator_get_config@GetDeviceStatus')
  nil
ensure
  propagator_connection.close if propagator_connection
end
# #

# Method to connect propagator to get config inside it:
def propagator_get_config(ip_list, port)
  received_config = nil
  ip_list.each do |ip|
    received_config = config_request(ip, port)
    break if received_config || (ip == ip_list.last)
  end
  received_config ? check_recieved_config(received_config) : 5
end
# #

# Method to check recieved config:
def check_recieved_config(config)
  unless config.is_a?String
    initializing_error(9,
                       'Undefined ERROR occurred. Check system logs.
                              #propagator_get_config@GetDeviceStatus')
    return 5
  end
  config.gsub!(/u"/, '"') && config.delete!("\n")
  YAML.safe_load(config)
end
# #

# Methot to gather propagator ip from recieved config data:
def get_propagator_ip(config)
  return '' unless config.is_a? Array
  # Return propagator IP:
  config[3].to_s
end
# #

# Method to connection to propagator for break command:
def master_device_break(ip, master_port)
  propagator_connection = TCPSocket.new(ip, master_port)
  propagator_connection.print(["break"])
  break_recieved = Timeout.timeout(10) { propagator_connection.gets }
  propagator_connection.close
  raise 'Break recieve is NULL! #propagator_break@GetDevicesStatus' if
      break_recieved.nil?
  20
rescue StandardError => error
  # debug
  p 'in master_device_break rescue'
  initializing_error(9, error.inspect + ' #propagator_break@GetDeviceStatus')
  5
end
# #

# Method for condition process in <get_devices_status> method:
def get_condition_response(master_port, start_package, config)
  if config == 1
    20
  elsif config == start_package
    10
  elsif config != start_package
    master_device_break(get_propagator_ip(config), master_port)
  else
    initializing_error(9,
                       'Undefined ERROR occurred. Check system logs. #get_condition_response@GetDeviceStatus')
    5
  end
end
# #

# Method to get devices current status:
def get_devices_status(start_package, all_ip, ini_port, master_port)
  # Get config data from device if there is:
  device_config = propagator_get_config(all_ip, ini_port)
  # Decide what is device status:
  # Return 5 or 10 or 20, according to status of device.
  get_condition_response(master_port, start_package, device_config)
end
# # # #

# Method for scan devices on local network, through on IP:
def scan_devices
  ip_list = []
  (0..255).to_a.each do |series|
    begin
      connection = Socket.tcp("192.168.0.#{series}", INI_PORT, connect_timeout: 0.15)
      connection.print('Device is found.')
      ip_list << "192.168.0.#{series}"
      connection.close
    rescue SystemCallError => err
      puts err.inspect + ' #scan_devices'
      connection.close if connection
    end
  end

  new_file = File.new(IP_PATH + 'all_devices.json', 'w')
  new_file.write(ip_list.to_json)
  new_file.close
end
# #

# Method to control the config file(s) directory:
def config_directory_control
  if !Dir.exist?(IP_PATH)
    '<< Configuration directory is NOT exist! >>'
  elsif !File.exist?(IP_PATH + 'all_devices.json')
    '<< Devices_IP_List file is NOT exist! >>'
  end
end
# #

# Method to set master device's IP:
def master_ip_set(ip)
  master_ip_file = File.new(IP_PATH + 'master_ip.json', 'w')
  master_ip_file.write([ip].to_json)
  master_ip_file.close
end
# #

# Method to create EMPTY master device's IP file:
def master_ip_file_create
  master_file = File.new(IP_PATH + 'master_ip.json', 'w+')
  master_file.write([])
  master_file.close
  []
end
# #

# Method to get master device's IP:
def master_ip_get
  if File.exist?(IP_PATH + 'master_ip.json')
    master_ip = JSON.parse(File.read(IP_PATH + 'master_ip.json'))
    all_ip = read_all_ip
    # Check the master device's IP is in all device's IPs list!:
    master_ip = master_ip_file_create unless all_ip.include?(master_ip[0])
  else
    master_ip = master_ip_file_create
  end
  master_ip
rescue StandardError => error
  puts error.inspect + ' #master_ip_get'
  master_ip_file_create
end
# #

# Method to read all device's IPs from file:
def read_all_ip
  JSON.parse(File.read(IP_PATH + 'all_devices.json'))
rescue StandardError => error
  puts error.inspect + ' #read_all_ip'
  []
end
# #

# Method to eleminate selected device's IPs which is not in the
# all device's IPs:
def eleminate_undefined_ip
  all_ip = read_all_ip
  # If 'slaves_ip.json' file is too big, stack to RAM entire of file
  # may be cause a problem.
  slaves_ip = JSON.parse(File.read(IP_PATH + 'slaves_ip.json'))
  slaves_ip.each do |key, value|
    slaves_ip.delete(key) unless all_ip.include?(value)
  end
  # Add new slave device's IPs to 'slave_ip.json' file:
  new_slave_ip_file = File.new(IP_PATH + 'slaves_ip.json', 'w')
  new_slave_ip_file.write(slaves_ip.to_json)
  new_slave_ip_file.close
  slaves_ip
end
# #

# Method to add/remove slave ip to "slave_ip.json" file:
def slave_ip_add_del(ip_arr, mod)
  slaves = read_slaves_ip.values
  # Mod: 'add' / 'remove'
  case mod
  when 'add'
    ip_arr.each { |add_ip| slaves << add_ip unless slaves.include?(add_ip) }
  when 'remove'
    ip_arr.each { |rem_ip| slaves.delete(rem_ip) }
  else
    initializing_error(11, 'Undefined error occured. #slave_ip_add_del')
  end
  # Call method for numerating and saving to file:
  numerate_and_save_slaves(slaves)
rescue StandardError => error
  initializing_error(11, error.inspect)
end
# #

# Method to numerate slave IPs and add the IP array to 'slave_ip.json' file:
def numerate_and_save_slaves(ip_array)
  slaves_hash = {}
  # Numerate:
  ip_array.each_with_index do |val, index|
    slaves_hash.store("Slave-#{index + 1}", val.to_s)
  end
  # Save to file:
  slave_file = File.new(IP_PATH + 'slaves_ip.json', 'w')
  slave_file.write(slaves_hash.to_json)
  slave_file.close
end
# #

# Method to create new EMPTY slave device's IPs file and return empty hash {}:
def slave_ip_file_create
  slaves_file = File.open(IP_PATH + 'slaves_ip.json', 'w+')
  slaves_file.write({})
  slaves_file.close
  {}
end
# #

# Method to read the selected device's IPs:
def read_slaves_ip
  if !File.exist?(IP_PATH + 'slaves_ip.json') ||
     !(JSON.parse(File.read(IP_PATH + 'slaves_ip.json')).is_a? Hash)
    slave_ip_file_create
  else
    eleminate_undefined_ip
  end
  # If 'slave_ip.json' file is broken, handle the error with rescue:
rescue StandardError => error
  puts error.inspect + ' #read_slaves_ip'
  slave_ip_file_create
end
# #

# Method to create PIN file for slected device's IPs:
def pin_file_create(passive_slaves_ip, active_slaves_ip)
  # Delete PIN files which are related with unselected device's IPs as
  # slaves:
  passive_slaves_ip.each do |unused_ip|
    File.delete(IP_PATH + "#{unused_ip}.json") if
        File.exist?(IP_PATH + "#{unused_ip}.json")
  end

  # Create PIN files which are related with selected device's IPs as
  # slaves:
  active_slaves_ip.each do |slave_ip|
    unless File.exist?(IP_PATH + "#{slave_ip}.json")
      pin_file = File.new(IP_PATH + "#{slave_ip}.json", 'w')
      pin_file.write(PIN_LIST.to_json)
      pin_file.close
    end
    next
  end
end
# #

# Method to determine selectable device's IPs, delete device's IPs
# selected as slave from all device's IPs:
def determine_selectable_ip(all_ip, slaves_ip)
  determined_ip = []
  all_ip.each do |ip|
    determined_ip << ip unless slaves_ip.include?(ip)
  end
  determined_ip
end
# #

# Method for "synthesize_ip_hash" hash assignment progress:
def assign_hash
  synthes = {}
  slaves_ip = read_slaves_ip

  synthes['all_ip'] = read_all_ip
  synthes['slaves_ip'] = slaves_ip.values
  synthes['master_ip'] = master_ip_get
  synthes['selectable_ip'] = determine_selectable_ip(synthes['all_ip'],
                                                     synthes['slaves_ip'])
  synthes['devices_count'] = synthes['all_ip'].length
  synthes['slaves_name'] = slaves_ip.keys
  synthes
end
# #

# Method to synthesize common IP hash:
def synthesize_ip_hash
  # sytnthesized_ip_hash
  # {
  #   'all_ip'
  #   'slaves_ip'
  #   'master_ip'
  #   'selectable_ip'
  #   'devices_count'
  #   'slaves_name'
  # }

  # Create synthesized ip hash via assignments:
  synthesized_ip_hash = assign_hash
  # Create PIN files related with selected device's IPs as slave.
  pin_file_create(synthesized_ip_hash['selectable_ip'],
                  synthesized_ip_hash['slaves_ip'])
  # Return synthesized ip hash:
  synthesized_ip_hash
end
# # # #

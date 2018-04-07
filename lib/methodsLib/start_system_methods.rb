# Method to start master device:
def start_master_device(ip, ini_port, config)
  master_connection = Socket.tcp(ip, ini_port)
  master_connection.print(["setMaster", Time.now.to_s].to_json)
  sleep 1
  master_connection.print(config.to_json)
  master_connection.close
end
# #

# Method to start slave devices:
def start_slave_devices(slaves_ip, ini_port, config)
  slaves_ip.each_with_index do |ip, index|
    slave_connection = Socket.tcp(ip, ini_port)
    slave_connection.print(["setSlave##{index + 1}", Time.now.to_s].to_json)
    sleep 1
    slave_connection.print(config.to_json)
    slave_connection.close
  end
end
# #

# Method for condition in <start_devices> method:
def start_devices_condition(response, config)
  if response == 10
    initializing_error(1, 'Devices are already running, system is continued.')
  elsif response == 20
    start_slave_devices($device_start_settings['slaves'], INI_PORT, config)
    start_master_device($device_start_settings['master'][0], INI_PORT, config)
    initializing_error(1, 'Initialization is verified. Devices are started.')
  else
    initializing_error(5, ' Undefined condition occurs, read logs. #start_devices_condition@StartDevices')
  end
rescue StandardError => error
  initializing_error(5, error.inspect + ' #start_devices_condition@StartDevices')
  nil
end
# #

# Method to start devices. Send command to devices declare them what they are,
# slave or master:
def start_devices(start_package)
  # Get devices status:
  status_response = get_devices_status(start_package, read_all_ip, INI_PORT, MASTER_PORT)
  # Condition part; start devices:
  start_devices_condition(status_response, start_package)
end
# #

# Method to test master device connection:
def master_connection_test(master_ip, master_port)
  connection = TCPSocket.new(master_ip, master_port)
  connection.print('Connection test..')
  connection.close
end
# #

# Method for starter section of the <on_off_system> method (part-I):
def on_off_starter_one
  start_package = prepare_start_package
  if start_package.count < 7
    initializing_error(6, 'Start package is broken. Try again, or read logs.')
    return 'Start package is broken. Try again, or read logs.'
  end
  start_devices(start_package)
end
# #

# Method for starter section of the <on_off_system> method (part-II):
def on_off_starter_two(master_ip)
  on_off_starter_one
  sleep 3
  # Check "$initialize_error" value:
  if $initialize_error[0] == 1
    # Test master device connection:
    master_connection_test(master_ip, MASTER_PORT)
    # Run communication thread:
    interval = $server_interval_time
    # CommunicationThread:
    $pika.run_pikachu(master_ip, MASTER_PORT, interval)
    $comm_thread_mutex.synchronize { $comm_thread_sync.wait($comm_thread_mutex) }
    true
  else
    $system_status = false
  end
rescue StandardError => error
  initializing_error(6, error.inspect + ' #on_off_starter_two@OnOffSystem')
  $system_status = false
end
# #

# Method for on/off system:
def on_off_system(command, master_ip)
  if command == 5
    # CommunicationThread starter:
    return unless on_off_starter_two(master_ip)
    # Start the BoundThread:
    $bulba.run_bulbasaur
    # Start the CheckpointThread:
    $butfree.run_butterfree
  elsif command == 10
    # Kill the BoundThread
    $bulba.standoff_bulbasaur
    # Kill the CheckpointThread:
    $butfree.butterfree_stop
    # Kill the CommunicationThread:
    $pika.stop_pikachu
  else
    initializing_error(8, 'Undefined Command. More info take system log.')
  end
end
# # # #

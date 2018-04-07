# Requirements:
require 'timeout'
require 'yaml'
require 'csv'
##

# ThreadClass(s):
require_relative '../../lib/threadClass(s)/communication_thread_class.rb'
require_relative '../../lib/threadClass(s)/bound_thread_class.rb'
require_relative '../../lib/threadClass(s)/checkpoint_thread_class.rb'
##

# OtherClass(s):
require_relative '../../lib/otherClass(s)/record_management_class.rb'
require_relative '../../lib/otherClass(s)/overflow_management_class.rb'
require_relative '../../lib/otherClass(s)/record_filtering_class.rb'
##

# MethodsLib:
require_relative '../../lib/methodsLib/before_start_system_methods.rb'
require_relative '../../lib/methodsLib/ip_preparing_methods.rb'
require_relative '../../lib/methodsLib/start_system_methods.rb'
##

# CONSTANTS DEFINITIONS
#
# IP_PATH => Directory of qll .json files. It must be defined default !!
#
# PIN_LIST => It contains pins which are on the devices and
# sensors are connected. Also, it must be defined default!!
#
IP_PATH = # YOUR DIRECTORY PATH for proSen USAGE
SAVE_FILE_PATH = IP_PATH + 'save_file.json'.freeze
BOUND_PATH = IP_PATH + 'bounds.json'.freeze
PIN_LIST = %w[11_13 16_18 29_31].freeze
INI_PORT = 9000
MASTER_PORT = 5554
##

# $GLOBAL_VARIABLES AND INITIAL CONDITIONS:
$initialize_error = []
$device_start_settings = {}

# Assign the "device_interval_time":
begin
  return $device_interval_time = 8 unless
      File.exist?(IP_PATH + 'start_package.json')
  start_conf = JSON.parse(File.read(IP_PATH + 'start_package.json'))
  raise 'Start_package is broken!' unless
      start_conf.is_a?(Array) && (start_conf.length >= 6)
  $device_interval_time = start_conf[1].to_i
rescue StandardError => err
  p "ERROR: #{err.message}"
  $device_interval_time = 9
end
# #

# Some global values:
$server_interval_time = $device_interval_time + 1
# BoundThread mutex:
$bound_thread_mutex = Mutex.new
# CommunicationThread muex and conditionVariable:
$comm_thread_mutex = Mutex.new
$comm_thread_sync = ConditionVariable.new
# CheckpointThread mutex:
$checkpoint_thread_mutex = Mutex.new
# System status, if system is running, it is TRUE; else it is FALSE:
$system_status = false
# #

# "$pika" is global CommunicationThread variable.
# "$balba" is global BoundThread variable.
# "$butfree" is global CheckpointThread variable.
$pika = CommunicationThread.new
$bulba = BoundThread.new
$butfree = CheckpointThread.new
# Initialize Error-initial value:
unless $initialize_error[0]
  initializing_error(7, 'System OK.')
end
# Class for check sensor's humidity and temperature bounds
# and organize them. It's a thread class, also.
class BoundThread
  attr_accessor :bulbasaur, :bulbasaur_stopper
  # Method to initialize instance variables:
  def initialize
    @last_error = 'System OK, bound file check process NOT running.'
    @bulbasaur_stopper = true
  end
  # #

  # Method to get last error:
  def last_error
    $bound_thread_mutex.synchronize { @last_error }
  end
  # #

  # Method to run "@bulbasaur", bound thread:
  def run_bulbasaur
    @bulbasaur.kill if bulbasaur_is_runnig?
    @bulbasaur_stopper = false
    @bulbasaur = Thread.new { main_process_bulbasaur }
  end
  # #

  # Method to stop "@bulbasaur":
  def standoff_bulbasaur
    if bulbasaur_is_runnig?
      stop_bulbasaur
    else
      @bulbasaur_stopper = true
    end
  rescue StandardError => error
    @bulbasaur.kill if bulbasaur_is_runnig?
    $bound_thread_mutex.synchronize do
      @last_error = error.inspect + ' #standoff_bulbasaur'
    end
  end
  # #

  # Private methods:

  private

  # Method to look for "@bulbasaur" is running:
  def bulbasaur_is_runnig?
    (defined? @bulbasaur) && (@bulbasaur.is_a? Thread) && @bulbasaur.alive?
  end
  # #

  # Method to stop "@bulbasaur":
  def stop_bulbasaur
    $bound_thread_mutex.synchronize { @bulbasaur_stopper = true }
    @bulbasaur.wakeup if @bulbasaur.status == 'sleep'
  end
  # #

  # Method for rescue block of main process:
  def main_resc_block(err)
    $bound_thread_mutex.synchronize do
      @last_error = err.inspect + ' #main_process_bulbasaur'
      @bulbasaur_stopper = true
    end
    Thread.current.kill
  end
  # #

  # Method to check bound file validity and read bound values from
  # file:
  def bound_file_read
    return false unless File.exist?(BOUND_PATH)
    data = JSON.parse(File.read(BOUND_PATH))
    # After read file, delete it:
    File.delete(BOUND_PATH)
    data
  rescue StandardError => error
    puts error.inspect + ' #bound_file_read'
    File.delete(BOUND_PATH)
    false
  end
  # #

  # Method to get bounds from inserted file and save them
  # to database:
  def bound_save_to_db
    bounds = bound_file_read
    return unless bounds
    # 'bounds' variable format:
    # [["sensor_1", temperature, humudity], ["sensor_2", temperature, humudity]]
    bounds.each do |elm|
      sens = Sensor.find_by_name(elm[0].to_s)
      # If 'sensor name' missed, then next iteration.
      next unless sens
      # Retrieve related sensor's bound record:
      related_bnd = Bound.find_by_sensor_id(sens.id)
      if related_bnd
        related_bnd.update(temperature_bound: elm[1].to_f,
                           humidity_bound: elm[2].to_f,
                           updated_at: Time.now)
      else
        # If did NOT find related bound record, create it:
        Bound.create(sensor: sens, temperature_bound: elm[1].to_f,
                     humidity_bound: elm[2].to_f, created_at: Time.now)
      end
    end
  end
  # #

  # Method to break the main process:
  def main_process_break
    # If stopper is true, then kill the thread.
    return false unless $bound_thread_mutex.synchronize { @bulbasaur_stopper }
    $bound_thread_mutex.synchronize do
      @last_error = 'System OK, bound file check process is stopped.'
    end
    Thread.current.kill
  end
  # #

  # Method for main proces of '@bulbasaur' bound thread:
  def main_process_bulbasaur
    Kernel.loop do
      # Kill thread if break variable is activated:
      main_process_break
      # Scan for new bounds (main_process):
      bound_save_to_db
      # Change '@last_error', everything is OK:
      $bound_thread_mutex.synchronize do
        @last_error = 'System OK, the bound file check is running..'
      end
      # Scan bound file every 30 second:
      sleep 15
    end
  rescue StandardError => error
    main_resc_block(error)
  end
  # #
end
# # # #

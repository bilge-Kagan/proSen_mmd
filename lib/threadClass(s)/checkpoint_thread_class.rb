# Class for saving records once per hour, like checkpoint..
class CheckpointThread
  attr_accessor :butterfree, :butterfree_stopper
  # Method to initialize instance variables:
  def initialize
    @last_error = 'System OK, checkpoint process NOT running.'
    @butterfree_stopper = true
  end
  # #

  # Method to get last error:
  def last_error
    $checkpoint_thread_mutex.synchronize { @last_error }
  end
  # #

  # Method to run "@butterfree", the checkpoint thread:
  def run_butterfree
    @butterfree.kill if butterfree_is_running?
    @butterfree_stopper = false
    @butterfree = Thread.new { butterfree_main_process }
  end
  # #

  # Method to stop "@butterfree"
  def butterfree_stop
    if butterfree_is_running?
      $checkpoint_thread_mutex.synchronize { @butterfree_stopper = true }
      @butterfree.wakeup if @butterfree.status == 'sleep'
    else
      @butterfree_stopper = true
    end
  rescue StandardError => error
    @butterfree.kill if butterfree_is_running?
    $checkpoint_thread_mutex.synchronize do
      @last_error = error.inspect + ' #butterfree_stop'
    end
  end
  # Private methods:

  private

  # Method to look for "@butterfree" is running:
  def butterfree_is_running?
    (defined? @butterfree) && (@butterfree.is_a? Thread) && (@butterfree.alive?)
  end
  # #

  # Method to break teh process loop:
  def break_main_process
    # Check for "@butterfree_stopper":
    return false unless
        $checkpoint_thread_mutex.synchronize { @butterfree_stopper }
    $checkpoint_thread_mutex.synchronize do
      @last_error = 'System OK, checkpoint process is stopped.'
    end
    # Kill the butterfree thread:
    Thread.current.kill
  end
  # #

  # Method to query measurements which measured last an hour:
  def records_in_last_hour
    # Retrieve data as array:
    recs = Measurement.measured_last_hour
    (recs.is_a? Array) && (recs.count != 0) ? recs : false
  rescue StandardError => error
    puts error.inspect + ' #measured_last_hour'
    $checkpoint_thread_mutex.synchronize do
      @last_error = error.inspect + ' #measured_last_hour' \
                    ' - System is running..'
    end
    false
  end
  # #

  # Method to save to file the retrieved records for an hour:
  def records_save_to_file
    # Get records and control:
    data = records_in_last_hour
    return false unless data
    # Open file and save 'data':
    begin
      save_file = File.new(SAVE_FILE_PATH, 'w')
      save_file.write(data)
      save_file.close
    rescue StandardError => error
      save_file.close if save_file.closed?
      puts error.inspect + ' #records_save_to_file'
    end
  end
  # #

  # Method for rescue block of main process:
  def main_resc_block(error)
    $checkpoint_thread_mutex.synchronize do
      @last_error = error.inspect + ' #butterfree_main_process' \
                    ' - System is NOT running!'
      @butterfree_stopper = true
    end
    Thread.current.kill
  end
  # #

  # Method to main process of "@butterfree" checkpoint thread:
  # Every hour, get measurements records which measured last hour.
  # Then save them to 'SAVE_FILE'.
  def butterfree_main_process
    Kernel.loop do
      # Check for break:
      break_main_process
      # Get records and save to file:
      records_save_to_file
      # Change the "@last_error" status:
      $checkpoint_thread_mutex.synchronize do
        @last_error = 'System OK, the checkpoint process is running..'
      end
      # Sleep 1 hour:
      sleep(60 * 60)
    end
  rescue StandardError => error
    main_resc_block(error)
  end
end
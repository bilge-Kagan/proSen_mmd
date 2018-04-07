# Class for communication between server and devices on new thread:
class CommunicationThread
  attr_accessor :pikachu, :pikachu_stopper
  # Method to initialize instance variables:
  def initialize
    @thread_stop_sync = ConditionVariable.new
    @pikachu_stopper = true
    @retry_count = 0
    @last_data_time = nil
    @last_error = 'System OK, communication NOT running.'
  end
  # #

  # Method to get retry count in mutex from CommmunicationClass:
  def retry_count
    $comm_thread_mutex.synchronize { @retry_count }
  end
  # #

  # Method to get last error:
  def last_error
    $comm_thread_mutex.synchronize { @last_error }
  end
  # #

  # Method to run "@pikachu" thread for main communication process:
  def run_pikachu(master_ip, master_port, interval)
    @pikachu_stopper = false
    @pikachu.kill if pikachu_is_running?
    @pikachu = Thread.new { main_process_pikachu(master_ip, master_port, interval) }
    # Maybe we need this, but not now:
    # @pikachu.abort_on_exception = true
  end
  # #

  # Method to stop "@pikachu" communication thread:
  def stop_pikachu
    if pikachu_is_running?
      @pikachu.wakeup if @pikachu.status == 'sleep'
      $comm_thread_mutex.synchronize do
        @pikachu_stopper = true
        @thread_stop_sync.wait($comm_thread_mutex)
      end
    else
      @pikachu_stopper = true
    end
    @retry_count = 0
    $system_status = false
    @last_error = 'System OK, communication stopped.'
  rescue StandardError => error
    stop_rescue_block(error.inspect + ' #stop_pikachu@CommunicationThread')
  end
  # #

  # Private methods, they're using in class:

  private

  # Method to define rescue block for <stop_pikachu> method:
  def stop_rescue_block(error)
    @pikachu.kill if pikachu_is_running?
    $comm_thread_mutex.synchronize do
      @last_error = error
      $system_status = pikachu_is_running? ? true : false
      @retry_count = 0
      nil
    end
  end
  # #

  # Method to look for "@pikachu" thread is running:
  def pikachu_is_running?
    (defined? @pikachu) && (@pikachu.is_a?Thread) && @pikachu.alive? ? true : false
  end
  # #

  # Method to calculate waiting time of "@pikachu" thread.
  # With this method, record query commands sending in specified
  # time:
  def wait_pikachu(started_time, interval)
    process_time = (Time.now - started_time).to_i
    reamining_time = interval - process_time
    ## DEBUG:
    p 'waiting..'
    sleep reamining_time if reamining_time > 0
  end
  # #

  # Method for communication behaviour:
  def comm_behaviour(mode, master_conn, message)
    case mode
    when 1
      master_conn.print(message)
      data = Timeout.timeout(8) { master_conn.gets }
      # Check data is array, else return false:
      raise 'Received data is NOT valid!' unless data
      data
    when 2
      master_conn.print(message)
    else
      p 'Wrong mode at <comm_behaviour>'
      false
    end
  rescue StandardError => error
    puts error.inspect + ' #comm_behaviour@CommunicationThread'
    $comm_thread_mutex.synchronize { @retry_count += 1 }
    false
  ensure
    master_conn.close if master_conn
  end
  # #

  # Method to query to devices:
  def query_to_device(master_ip, master_port, mode, message)
    master_connect = TCPSocket.new(master_ip, master_port)
    comm_behaviour(mode, master_connect, message)
  rescue StandardError => error
    master_connect.close if master_connect
    $comm_thread_mutex.synchronize do
      puts error.inspect + ' #query_to_device'
      @last_error = error.inspect
      $comm_thread_sync.signal
      @retry_count += 1
      false
    end
  end
  # #

  # Method fro main process break part:
  def main_process_break(master_ip, master_port)
    return unless $comm_thread_mutex.synchronize { @pikachu_stopper }
    query_to_device(master_ip, master_port, 2, ["break"])
    $comm_thread_mutex.synchronize { @thread_stop_sync.signal }
    Thread.current.kill
  end
  # #

  # Method to determine last records time part:
  def determine_last_data_time
    if @last_data_time
      @last_data_time
    elsif Sensor.exists?
      Sensor.order(:last_record_time).last.last_record_time.localtime.to_f
    else
      0
    end
  end
  # #

  # Method to save new measurement data to << SQL >> :
  def m_data_save(data_piece)
    # Organize the data array:
    data_piece[0].tr!('#', '@')
    # Save process:
    sens = Sensor.find_or_create_by(name: data_piece[0].to_s)
    Measurement.create(sensor: sens,
                       temperature: data_piece[1].to_f,
                       humidity: data_piece[2].to_f,
                       record_time: Time.at(data_piece[3].to_f).localtime)
  end
  # #

  # Method to save data come from device in main process of "@pikachu":
  def main_process_data_save(data)
    $comm_thread_mutex.synchronize { @retry_count = 0 }
    data_array = YAML.safe_load(data)
    data_array.uniq!
    data_array.each do |piece_of_data|
      unless piece_of_data.is_a?(Array) && (piece_of_data.count == 4)
        p 'Recieved data-piece is NOT valid!'
        next
      end
      # Measurement saving:
      m_data_save(piece_of_data)
      #
      @last_data_time = piece_of_data[3].to_f
    end
  rescue StandardError => error
    $comm_thread_mutex.synchronize do
      @last_error = error.inspect + ' #main_process_data_save'
    end
  end
  # #

  # Method for last no-error part of main process of "@pikachu":
  def main_process_last_part(started_time, interval)
    $comm_thread_mutex.synchronize do
      @last_error = 'System OK, communication running.'
      $system_status = true
      $comm_thread_sync.signal
    end
    wait_pikachu(started_time, interval)
  end
  # #

  # Method to create message and send for getting data:
  # returns @data
  def message_create_and_send(master_ip, master_port, time_part)
    message = ["getInterval", time_part, Time.now.to_f]
    query_to_device(master_ip, master_port, 1, message)
  end
  # #

  # Method for another rescue block in main process of "@pikachu" thread:
  def second_rescue_block
    $system_status = false
    @retry_count = 0
    $comm_thread_sync.signal
  end
  # #

  # Method to main process of communication thread, "@pikachu":
  def main_process_pikachu(master_ip, master_port, interval)
    Kernel.loop do
      ## DEBUG::
      p 'loop started'
      start_time = Time.now
      # Kill "@pikachu" if break command recieved:
      main_process_break(master_ip, master_port)
      # Determine last time of recieved data:
      # Unnecessary! : @last_data_time = determine_last_data_time
      # Create message and send, to recieve data from master device:
      data = message_create_and_send(master_ip, master_port, determine_last_data_time)
      # Save the data received from master device:
      main_process_data_save(data) if data
      # Last check part of the Main process of "@pikachu" thread:
      main_process_last_part(start_time, interval)
    end
  rescue StandardError => error
    $comm_thread_mutex.synchronize do
      @last_error = error.inspect + ' #main_process - Communication is stopped!'
      second_rescue_block
    end
    Thread.current.kill
    nil
  end
  # #
end
# # # #

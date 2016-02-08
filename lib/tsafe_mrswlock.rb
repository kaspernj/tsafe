# A class that allows many simultanious read-synchronizations but locks both reading and writing while calling the write-synchronzie-method.
# This version does not work in JRuby! 'const_missing'-autoloader should automatically load the JRuby-version.
# It is not 'actually' thread-safe, but because of GIL, it wont bug up. If it was actually thread-safe, the performance would go down. So it only works with GIL.
class Tsafe::Mrswlock
  # Sets various variables.
  def initialize
    @reads = 0
    @w_mutex = Mutex.new
    @threads_read_stopped = []

    # This variable is used to allow reads from the writing thread (monitor-behavior).
    @locked_by = nil

    # This hash holds thread-IDs for threads that are reading.
    @reading_threads = {}
  end

  # Runs the given block through the read-synchronization.
  def rsync
    begin
      tid = Thread.current.__id__

      while @w_mutex.locked? && @locked_by != tid
        @threads_read_stopped << Thread.current
        Thread.stop
      end

      @threads_read_stopped.delete(Thread.current)
      @reading_threads[tid] = true
      @reads += 1
      yield
    ensure
      @reading_threads.delete(tid)
      @reads -= 1
    end
  ensure
    # Restart stopped writing-thread.
    @threads_write_stopped.run if @threads_write_stopped && @reads <= 0
  end

  # Runs the given block through the write-synchronization (locks both reading and writing).
  #===Examples
  #  lock.wsync do
  #    #do something within lock.
  #  end
  def wsync
    @w_mutex.synchronize do
      begin
        tid = Thread.current.__id__
        @locked_by = tid

        # Wait for any reads to finish that might have started while we were getting the lock.
        # Also allow write if there is only one reading thread and that reading thread is the current thread.
        while @reads > 0
          raise ThreadError, "Deadlock: Writing is not allowed while reading." if @reading_threads.key?(tid)
          @threads_write_stopped = Thread.current
          Thread.stop
        end

        yield
      ensure
        @locked_by = nil
        @threads_write_stopped = nil
      end
    end
  ensure
    # Restart any stopped reading-threads.
    while (thread = @threads_read_stopped.shift)
      thread.run
    end
  end
end

require "java"

# A class that allows many simultanious read-synchronizations but locks both reading and writing while calling the write-synchronzie-method.
# This is the JRuby-version and will not work under anything else. It uses 'java.util.concurrent.locks.ReentrantReadWriteLock' instead of doing the locking in Ruby.
class Tsafe::Mrswlock
  # Sets various variables.
  def initialize
    @lock = java.util.concurrent.locks.ReentrantReadWriteLock.new

    # This hash holds thread-IDs for threads that are reading.
    @reading_threads = {}
  end

  # Runs the given block through the read-synchronization.
  def rsync
    @lock.read_lock.lock
    tid = Thread.current.__id__
    @reading_threads[tid] = true

    begin
      yield
    ensure
      @reading_threads.delete(tid)
      @lock.read_lock.unlock
    end
  end

  # Runs the given block through the write-synchronization (locks both reading and writing).
  #===Examples
  #  lock.wsync do
  #    #do something within lock.
  #  end
  def wsync
    tid = Thread.current.__id__
    raise ThreadError, "Deadlock: Writing is not allowed while reading." if @reading_threads.key?(tid)

    begin
      @wlock_by = tid
      @lock.write_lock.lock
      yield
    ensure
      @lock.write_lock.unlock
    end
  end
end

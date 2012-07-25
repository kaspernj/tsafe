#A class that allows many simultanious read-synchronizations but locks both reading and writing while calling the write-synchronzie-method.
class Tsafe::Mrswlock
  @@debug = false
  
  # Sets various variables.
  def initialize
    @reads = 0
    @w_mutex = Mutex.new
  end
  
  # Runs the given block through the read-synchronization.
  def rsync
    begin
      while @w_mutex.locked?
        Thread.pass
        print "Passed because lock.\n" if @@debug
      end
      
      @reads += 1
      print "Reading more than one at a time! (#{@reads})\n" if @@debug and @reads >= 2
      yield
    ensure
      @reads -= 1
    end
  end
  
  # Runs the given block through the write-synchronization (locks both reading and writing).
  # ===Examples
  #  lock.wsync do
  #    #do something within lock.
  #  end
  def wsync
    @w_mutex.synchronize do
      #Wait for any reads to finish that might have started while we were getting the lock.
      while @reads > 0
        Thread.pass
        print "Passed because reading.\n" if @@debug
      end
      
      yield
    end
  end
  
  #This module can be included in order to painlessly make a thread-safe multi-reader-single-writer thread-safe copy of a class.
  #===Examples
  # class Tsafe::MonHash < ::Hash
  #   @@tsafe_mrswlock_w_methods = [:[]=, :clear, :delete, :delete_if, :keep_if, :merge!, :rehash, :reject!, :replace, :select!, :shift, :store, :update, :values_at]
  #   @@tsafe_mrswlock_r_methods = [:each, :each_key, :each_pair, :each_value]
  #   include Tsafe::Mrswlock::SynModule
  # end
  module SynModule
    def self.included(base)
      base.to_s.split("::").inject(Object, :const_get).class_eval do
        #Yields the given block within the read-lock.
        #===Examples
        # obj._tsafe_rsync do
        #   #do something within read-lock.
        # end
        def _tsafe_rsync(&block)
          @tsafe_mrswlock.rsync(&block)
        end
        
        #Yields the given block within the write-lock (and read-lock).
        #===Examples
        # obj._tsafe_wsync do
        #   #do something within write-lock.
        # end
        def _tsafe_wsync(&block)
          @tsafe_mrswlock.rsync(&block)
        end
        
        #Rename initialize.
        alias_method(:initialize_mrswlock, :initialize)
        
        #Make another initialize-method that spawns the lock and then calls the original initialize.
        define_method(:initialize) do |*args, &block|
          @tsafe_mrswlock = Tsafe::Mrswlock.new
          return initialize_mrswlock(*args, &block)
        end
        
        #Makes reader methods go through reader-lock.
        base.class_variable_get(:@@tsafe_mrswlock_r_methods).each do |mname|
          newmname = "tsafe_mrswlock_#{mname}".to_sym
          alias_method(newmname, mname)
          
          define_method(mname) do |*args, &block|
            @tsafe_mrswlock.rsync do
              return self.__send__(newmname, *args, &block)
            end
          end
        end
        
        #Makes writer methods go through writer-lock.
        base.class_variable_get(:@@tsafe_mrswlock_w_methods).each do |mname|
          newmname = "tsafe_mrswlock_#{mname}".to_sym
          alias_method(newmname, mname)
          
          define_method(mname) do |*args, &block|
            @tsafe_mrswlock.wsync do
              return self.__send__(newmname, *args, &block)
            end
          end
        end
      end
    end
  end
end
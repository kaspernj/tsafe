#A class that allows many simultanious read-synchronizations but locks both reading and writing while calling the write-synchronzie-method.
class Tsafe::Mrswlock
  @@debug = false
  
  #Sets various variables.
  def initialize
    @reads = 0
    @w_mutex = Mutex.new
  end
  
  #Runs the given block through the read-synchronization.
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
  
  #Runs the given block through the write-synchronization (locks both reading and writing).
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
  
  module SynModule
    def self.included(base)
      base.to_s.split("::").inject(Object, :const_get).class_eval do
        #Yields the given block within the read-lock.
        def _tsafe_rsync(&block)
          @tsafe_mrswlock.rsync(&block)
        end
        
        #Yields the given block within the write-lock (and read-lock).
        def _tsafe_wsync(&block)
          @tsafe_mrswlock.rsync(&block)
        end
        
        #Rename initialize.
        alias_method(:initialize_rwmutex, :initialize)
        
        #Make another initialize-method that spawns the lock and then calls the original initialize.
        define_method(:initialize) do |*args, &block|
          @tsafe_mrswlock = Tsafe::Mrswlock.new
          return initialize_rwmutex(*args, &block)
        end
        
        base.class_variable_get(:@@tsafe_rwmutex_r_methods).each do |mname|
          newmname = "tsafe_rwmutex_#{mname}".to_sym
          alias_method(newmname, mname)
          
          define_method(mname) do |*args, &block|
            @tsafe_mrswlock.rsync do
              return self.__send__(newmname, *args, &block)
            end
          end
        end
        
        base.class_variable_get(:@@tsafe_rwmutex_w_methods).each do |mname|
          newmname = "tsafe_rwmutex_#{mname}".to_sym
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
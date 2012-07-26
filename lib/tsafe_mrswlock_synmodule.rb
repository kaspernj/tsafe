# This module can be included in order to painlessly make a thread-safe multi-reader-single-writer thread-safe copy of a class.
#===Examples
#  class Tsafe::MonHash < ::Hash
#    @@tsafe_mrswlock_w_methods = [:[]=, :clear, :delete, :delete_if, :keep_if, :merge!, :rehash, :reject!, :replace, :select!, :shift, :store, :update, :values_at]
#    @@tsafe_mrswlock_r_methods = [:each, :each_key, :each_pair, :each_value]
#    include Tsafe::Mrswlock::SynModule
#  end
module Tsafe::Mrswlock_synmodule
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
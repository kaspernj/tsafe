#This module can be included on a class to make all method-calls synchronized (by using monitor). Examples with array and hash are below.
#
#===Examples
# class MySyncedClass < SomeOtherClassThatNeedsToBeSynchronized
#   include Tsafe::Monitored
# end
module Tsafe::Monitored
  def self.included(base)
    base.to_s.split("::").inject(Object, :const_get).class_eval do
      self.instance_methods.each do |method_name|
        #These two methods create warnings under JRuby.
        if RUBY_ENGINE == "jruby"
          next if method_name == :instance_exec or method_name == :instance_eval
        end
        
        new_method_name = "_ts_#{method_name}"
        alias_method(new_method_name, method_name)
        
        define_method method_name do |*args, &block|
          #Need to use monitor, since the internal calls might have to run not-synchronized, and we have just overwritten the internal methods.
          @_ts_mutex = Monitor.new if !@_ts_mutex
          @_ts_mutex.synchronize do
            return self._ts___send__(new_method_name, *args, &block)
          end
        end
      end
    end
  end
end
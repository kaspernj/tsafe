# Instances of this class proxies calls to a given-object by using a mutex or monitor.
#
#==== Examples
#  threadsafe_array = Tsafe::Proxy.new(:obj => [])
#  threadsafe_array << 5
#  ret = threadsafe_array[0]
#
#  threadsafe_array = Tsafe::Proxy.new(:obj => [], :monitor => true)
class Tsafe::Proxy
  # Spawns needed vars.
  def initialize(args)
    if args[:monitor]
      @mutex = Monitor.new
    elsif args[:mutex]
      @mutex = args[:mutex]
    else
      @mutex = Mutex.new
    end

    @obj = args[:obj]
  end

  # Proxies all calls to this object through the mutex.
  def method_missing(method_name, *args, &block)
    @mutex.synchronize do
      @obj.__send__(method_name, *args, &block)
    end
  end
end

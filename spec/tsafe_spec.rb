require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Tsafe" do
  it "should be able to spawn threadsafe proxy-objects" do
    arr = Tsafe::Proxy.new(:obj => {})
    
    0.upto(5) do |i|
      arr[i] = i
    end
    
    Thread.new do
      begin
        arr.each do |key, val|
          res = key + val
          sleep 0.1
        end
      rescue Exception => e
        print e.inspect
      end
    end
    
    5.upto(10) do |i|
      arr[i] = i
      sleep 0.1
    end
  end
  
  it "should be able to spawn special classes" do
    #Create new synchronized hash.
    arr = Tsafe::MonHash.new
    
    #Make sure we get the right results.
    arr[1] = 2
    
    res = arr[1]
    raise "Expected 2 but got '#{res}'." if res != 2
    
    #Set some values to test with.
    0.upto(5) do |i|
      arr[i] = i
    end
    
    #Try to call through each through a thread and then also try to set new values, which normally would crash the hash.
    Thread.new do
      begin
        arr.each do |key, val|
          res = key + val
          sleep 0.1
        end
      rescue Exception => e
        print e.inspect
      end
    end
    
    #This should not crash it, since they should wait for each other.
    5.upto(10) do |i|
      arr[i] = i
      sleep 0.1
    end
  end
end

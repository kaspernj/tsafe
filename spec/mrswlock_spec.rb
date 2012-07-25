require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require "timeout"

describe "Tsafe::Rwmutex" do
  it "should work with the modified hash" do
    Thread.abort_on_exception = true
    debug = false
    
    print "Setting initial values.\n" if debug
    hash = Tsafe::MonHash.new
    0.upto(15) do |count|
      realcount = 100000000 - count
      hash[realcount] = realcount
    end
    
    hash._tsafe_rsync do
    
    end
    
    hash._tsafe_wsync do
      
    end
    
    ts = []
    
    1.upto(10) do |tcount|
      print "Starting thread #{tcount}\n" if debug
      ts << Thread.new do
        1.upto(5000) do |count|
          hash[count] = count
          
          hash[count]
          hash.key?(count)
          
          hash.delete(count)
          
          hash.each do |key, val|
            #nothing...
          end
        end
      end
    end
    
    ts.each do |t|
      print "Joining #{t.__id__}\n" if debug
      t.join
    end
  end
  
  it "should work with manual lock creation" do
    debug = false
    
    hash = {}
    0.upto(15) do |count|
      realcount = 100000000 - count
      hash[realcount] = realcount
    end
    
    rwm = Tsafe::Mrswlock.new
    ts = []
    
    1.upto(10) do
      ts << Thread.new do
        1.upto(5000) do |count|
          rwm.wsync do
            hash[count] = count
          end
          
          rwm.rsync do
            hash[count]
            hash.key?(count)
          end
          
          rwm.wsync do
            hash.delete(count)
          end
          
          rwm.rsync do
            hash.each do |key, val|
              #nothing...
            end
          end
        end
      end
    end
    
    ts.each do |t|
      print "Joining #{t.__id__}\n" if debug
      t.join
    end
  end
  
  it "should be able to handle certain deadlocks" do
    hash = Tsafe::MonHash.new
    0.upto(1000) do |count|
      hash[count] = count
    end
    
    Timeout.timeout(3) do
      hash.keep_if do |key, val|
        hash.each do |key2, val2|
          #ignore.
        end
        
        if key > 500
          true
        else
          false
        end
      end
    end
    
    Timeout.timeout(3) do
      hash.each do |key, val|
        hash.delete(key)
      end
    end
  end
end

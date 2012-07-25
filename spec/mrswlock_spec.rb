require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Tsafe::Rwmutex" do
  it "should work!" do
    Thread.abort_on_exception = true
    debug = false
    
    print "Setting initial values.\n" if debug
    hash = Tsafe::MonHash.new
    0.upto(15) do |count|
      realcount = 100000000 - count
      hash[realcount] = realcount
    end
    
    ts = []
    
    1.upto(20) do |tcount|
      print "Starting thread #{tcount}\n" if debug
      ts << Thread.new do
        1.upto(10000) do |count|
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
  
  it "should work!" do
    debug = false
    
    hash = {}
    0.upto(15) do |count|
      realcount = 100000000 - count
      hash[realcount] = realcount
    end
    
    rwm = Tsafe::Mrswlock.new
    ts = []
    
    1.upto(20) do
      ts << Thread.new do
        1.upto(10000) do |count|
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
end

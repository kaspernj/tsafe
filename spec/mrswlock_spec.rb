require File.expand_path(File.dirname(__FILE__) + "/spec_helper")

require "timeout"

describe "Tsafe::Rwmutex" do
  it "should work with the modified hash" do
    Thread.abort_on_exception = true
    debug = false

    print "Setting initial values.\n" if debug
    hash = Tsafe::MonHash.new
    0.upto(15) do |count|
      realcount = 100_000_000 - count
      hash[realcount] = realcount
    end

    called = false
    hash._tsafe_rsync do
      called = true
    end

    raise "Expected to be called." unless called

    called = false
    hash._tsafe_wsync do
      called = true
    end

    raise "Expected to be called." unless called

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
            # nothing...
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
      realcount = 100_000_000 - count
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
              # nothing...
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

  it "should be able to read while writing from same thread while other threads are stressing" do
    hash = Tsafe::MonHash.new
    0.upto(1500) do |count|
      hash[count] = count
    end

    Timeout.timeout(14) do
      ts = []
      1.upto(20) do
        ts << Thread.new do
          hash.keep_if do |key, _val|
            hash.each do |key2, val2|
              # ignore.
            end

            if key > 500
              true
            else
              false
            end
          end
        end
      end

      ts.each(&:join)
    end
  end

  it "should not be able to write while reading from same thread" do
    hash = Tsafe::MonHash.new
    0.upto(1000) do |count|
      hash[count] = count
    end

    begin
      hash.each do |key, _val|
        hash.delete(key)
      end

      raise "Expected ThreadError but didnt get raised."
    rescue ThreadError # rubocop:disable Lint/HandleExceptions
      # Ignore - supposed to happen.
    end
  end

  it "should include thread-safe array" do
    arr = Tsafe::MonArray.new
    0.upto(1000) do |count|
      arr << count
    end

    ts = []
    0.upto(20) do
      ts << Thread.new do
        arr.each do |i|
          i + 100 / 5
        end

        0.upto(1000) do |count|
          arr << count + 1000
        end

        arr.delete_if do |count|
          count > 1000
        end
      end
    end

    ts.each(&:join)
  end
end

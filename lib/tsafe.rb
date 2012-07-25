require "monitor"

#This module contains various tools to handle thread-safety easily and pretty.
module Tsafe
  #Autoloader for subclasses.
  def self.const_missing(name)
    require "#{File.dirname(__FILE__)}/tsafe_#{name.to_s.downcase}.rb"
    raise "Still not loaded: '#{name}'." if !Tsafe.const_defined?(name)
    return Tsafe.const_get(name)
  end
  
  #JRuby can corrupt an array in a threadded env. Use this method to only get a synchronized array when running JRuby and not having to write "if RUBY_ENGINE"-stuff.
  def self.std_array
    return MonArray.new if RUBY_ENGINE == "jruby"
    return []
  end
end
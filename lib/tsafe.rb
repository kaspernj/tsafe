require "monitor"

# This module contains various tools to handle thread-safety easily and pretty.
module Tsafe
  # Autoloader for subclasses.
  def self.const_missing(name)
    file_path = "#{File.dirname(__FILE__)}/tsafe_#{name.to_s.downcase}"

    if RUBY_ENGINE == "jruby" && File.exist?("#{file_path}_jruby.rb")
      require "#{file_path}_jruby.rb"
    else
      require file_path
    end

    return Tsafe.const_get(name) if Tsafe.const_defined?(name)
    super
  end

  # JRuby can corrupt an array in a threadded env. Use this method to only get a synchronized array when running JRuby in order to not having to write "if RUBY_ENGINE"-stuff.
  def self.std_array
    return Tsafe::MonArray.new if RUBY_ENGINE == "jruby"
    []
  end
end

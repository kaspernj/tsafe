#Predefined synchronized array.
#
#===Examples
#  arr = Tsafe::MonArray.new
#  arr << 5
#  ret = arr[0]
class Tsafe::MonArray < ::Array
  @@tsafe_rwmutex_w_methods = [:<<, :collect, :collect!, :compact!, :delete, :delete_at, :delete_if, :drop, :drop_while, :fill, :flatten!, :insert, :keep_if, :map, :map!, :replace, :shuffle!, :slice!, :shift, :sort!, :sort_by!, :unshift]
  @@tsafe_rwmutex_r_methods = [:each, :each_index, :take_while]
  
  include Tsafe::Mrswlock_synmodule
end
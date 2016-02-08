# Predefined synchronized array.
#
#===Examples
#  arr = Tsafe::MonArray.new
#  arr << 5
#  ret = arr[0]
class Tsafe::MonArray < ::Array
  # rubocop:disable Style/ClassVars
  @@tsafe_mrswlock_w_methods = [:<<, :collect, :collect!, :compact!, :delete, :delete_at, :delete_if, :drop, :drop_while, :fill, :flatten!, :insert, :keep_if, :map, :map!, :replace, :shuffle!, :slice!, :shift, :sort!, :sort_by!, :unshift]
  @@tsafe_mrswlock_r_methods = [:each, :each_index, :take_while]
  # rubocop:enable Style/ClassVars

  include Tsafe::Mrswlock_synmodule
end

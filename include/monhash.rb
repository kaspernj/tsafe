#Predefined synchronized hash.
#
#===Examples
# h = Tsafe::MonHash.new
# h['test'] = 'trala'
# ret = h['test']
class Tsafe::MonHash < ::Hash
  @@tsafe_rwmutex_w_methods = [:[]=, :clear, :delete, :delete_if, :keep_if, :merge!, :rehash, :reject!, :replace, :select!, :shift, :store, :update, :values_at]
  @@tsafe_rwmutex_r_methods = [:each, :each_key, :each_pair, :each_value]
  
  include Tsafe::Mrswlock::SynModule
end
require 'data_tiering/model'

class Property < ActiveRecord::Base
  include DataTiering::Model
end

module DataTieringSyncSpec
  class Property < ActiveRecord::Base
    set_table_name "properties_secondary_0"
  end
end

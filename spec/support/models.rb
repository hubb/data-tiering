class Property < ActiveRecord::Base
end

module DataTieringSyncSpec
  class Property < ActiveRecord::Base
    set_table_name "properties_secondary_0"
  end
end

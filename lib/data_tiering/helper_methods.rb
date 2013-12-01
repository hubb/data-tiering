module DataTiering

  module HelperMethods

    def self.included(by)
      by.delegate :active_table_name_for, :active_scope_for, :aliased_active_table_sql, :to => :data_tiering_switch
    end

    def disable_data_tiering
      data_tiering_switch.disable
    end


    private

    def data_tiering_switch
      @data_tiering_switch ||= DataTiering::Switch.new
    end

  end

end

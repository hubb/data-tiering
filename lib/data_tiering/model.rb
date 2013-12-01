module DataTiering

  module Model

    def self.included(by)
      by.attr_protected :row_touched_at
    end

    def row_touched_at
      # this column does not play nice with rails
      # for example, time zones are off
      raise "this is a MySQL timestamp, don't use it as an AR attribute"
    end

  end

end

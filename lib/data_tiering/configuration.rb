module DataTiering
  class Configuration
    attr_accessor :models_to_sync, :search_enabled, :sync_enabled

    def initialize
      # @models_to_sync = [Property, Availability, Rate] to be re-introduced at some point
      @models_to_sync = []
      @search_enabled = true
      @sync_enabled   = true
    end
  end
end

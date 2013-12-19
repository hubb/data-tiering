module DataTiering
  class Configuration
    attr_accessor :search_enabled, :sync_enabled, :models_to_sync

    DEFAULT_SEARCH_ENABLED = true
    DEFAULT_SYNC_ENABLED   = true
    DEFAULT_MODELS_TO_SYNC = []

    def initialize
      @search_enabled = DEFAULT_SEARCH_ENABLED
      @sync_enabled   = DEFAULT_SYNC_ENABLED
      @models_to_sync = DEFAULT_MODELS_TO_SYNC
    end
  end
end

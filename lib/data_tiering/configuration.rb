module DataTiering
  class Configuration
    attr_accessor :models_to_sync,
                  :search_enabled,
                  :sync_enabled,
                  :env,
                  :cache,
                  :batch_size

    def initialize
      @models_to_sync = []
      @search_enabled = true
      @sync_enabled   = true
      @batch_size     = 100_000
    end
  end
end

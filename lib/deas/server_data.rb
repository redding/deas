module Deas

  class ServerData

    # The server uses this to "compile" its configuration for speed. NsOptions
    # is relatively slow everytime an option is read. To avoid this, we read the
    # options one time here and memoize their values. This way, we don't pay the
    # NsOptions overhead when reading them while handling a request.

    attr_reader :error_procs, :logger, :router, :template_source

    def initialize(args = nil)
      args ||= {}
      @error_procs     = args[:error_procs] || []
      @logger          = args[:logger]
      @router          = args[:router]
      @template_source = args[:template_source]
    end

  end

end

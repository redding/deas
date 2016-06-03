module Deas

  class ServerData

    # The server uses this to "compile" the common configuration data used
    # by the server instances, error handlers and routes. The goal here is
    # to provide these with a simplified interface with the minimal data needed
    # and to decouple the configuration from each thing that needs its data.

    attr_reader :error_procs, :template_source, :logger, :router

    def initialize(args = nil)
      args ||= {}
      @error_procs     = args[:error_procs] || []
      @template_source = args[:template_source]
      @logger          = args[:logger]
      @router          = args[:router]
    end

  end

end

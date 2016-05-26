module Deas

  class ServerData

    # The server uses this to "compile" the common configuration data used
    # by the server instances, error handlers and routes. The goal here is
    # to provide these with a simplified inteface with the minimal data needed
    # and to decouple the configuration from each thing that needs its data.

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

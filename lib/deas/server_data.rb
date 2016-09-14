module Deas

  class ServerData

    # The server uses this to "compile" the common configuration data used
    # by the server instances, error handlers and routes. The goal here is
    # to provide these with a simplified interface with the minimal data needed
    # and to decouple the configuration from each thing that needs its data.

    attr_reader :error_procs, :template_source, :logger, :router

    def initialize(args)
      args ||= {}
      @error_procs     = args[:error_procs] || []
      @template_source = args[:template_source]
      @logger          = args[:logger]
      @router          = args[:router]
    end

    def ==(other_server_data)
      if other_server_data.kind_of?(ServerData)
        self.error_procs     == other_server_data.error_procs     &&
        self.template_source == other_server_data.template_source &&
        self.logger          == other_server_data.logger          &&
        self.router          == other_server_data.router
      else
        super
      end
    end

  end

end

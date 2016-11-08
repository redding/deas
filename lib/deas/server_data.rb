module Deas

  class ServerData

    # The server uses this to "compile" the common configuration data used
    # by the server instances, error handlers and routes. The goal here is
    # to provide these with a simplified interface with the minimal data needed
    # and to decouple the configuration from each thing that needs its data.

    attr_reader :error_procs, :before_route_run_procs, :after_route_run_procs
    attr_reader :template_source, :logger, :router

    def initialize(args)
      args ||= {}
      @error_procs            = args[:error_procs] || []
      @before_route_run_procs = args[:before_route_run_procs] || []
      @after_route_run_procs  = args[:after_route_run_procs] || []
      @template_source        = args[:template_source]
      @logger                 = args[:logger]
      @router                 = args[:router]
    end

    def ==(other_server_data)
      if other_server_data.kind_of?(ServerData)
        self.before_route_run_procs == other_server_data.before_route_run_procs &&
        self.after_route_run_procs  == other_server_data.after_route_run_procs  &&
        self.error_procs            == other_server_data.error_procs            &&
        self.template_source        == other_server_data.template_source        &&
        self.logger                 == other_server_data.logger                 &&
        self.router                 == other_server_data.router
      else
        super
      end
    end

  end

end

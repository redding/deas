require 'deas/exceptions'
require 'deas/deas_runner'

module Deas

  class HandlerProxy

    attr_reader :handler_class_name, :handler_class

    def initialize(handler_class_name)
      @handler_class_name = handler_class_name
    end

    def validate!
      raise NotImplementedError
    end

    def run(server_data, request_data)
      # captures are not part of Deas' intended behavior and route matching -
      # they are a side-effect of using Sinatra.  remove them so they won't
      # be relied upon in Deas apps.  Remove all of this when Sinatra is removed.
      request_data.params.delete(:captures)
      request_data.params.delete('captures')

      # splats that Sinatra provides aren't used by Deas - they are a
      # side-effect of using Sinatra.  remove them so they won't be relied upon
      # in Deas apps.  Remove all of this when Sinatra is removed.
      request_data.params.delete(:splat)
      request_data.params.delete('splat')

      runner = DeasRunner.new(self.handler_class, {
        :logger          => server_data.logger,
        :router          => server_data.router,
        :template_source => server_data.template_source,
        :request         => request_data.request,
        :params          => request_data.params,
        :route_path      => request_data.route_path
      })

      runner.request.env.tap do |env|
        # make runner data available to Rack (ie middlewares)
        # this is specifically needed by the Logging middleware
        # this is also needed by the Sinatra error handlers so they can provide
        # error context.  This may change when we eventually remove Sinatra.
        env['deas.handler_class'] = self.handler_class
        env['deas.handler']       = runner.handler
        env['deas.params']        = runner.params
        env['deas.splat']         = runner.splat
        env['deas.route_path']    = runner.route_path

        # this handles the verbose logging (it is a no-op if summary logging)
        env['deas.logging'].call "  Handler: #{self.handler_class.name}"
        env['deas.logging'].call "  Params:  #{runner.params.inspect}"
        env['deas.logging'].call "  Splat:   #{runner.splat.inspect}" if !runner.splat.nil?
        env['deas.logging'].call "  Route:   #{runner.route_path.inspect}"
      end

      runner.run
    end

  end

end

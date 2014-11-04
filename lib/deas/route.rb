require 'deas/sinatra_runner'

module Deas

  class Route

    attr_reader :method, :path, :route_proxy, :handler_class

    def initialize(method, path, route_proxy)
      @method, @path, @route_proxy = method, path, route_proxy
    end

    def validate!
      @route_proxy.validate!
      @handler_class = @route_proxy.handler_class
    end

    def run(sinatra_call)
      args = {
        :sinatra_call => sinatra_call,
        :request      => sinatra_call.request,
        :response     => sinatra_call.response,
        :params       => sinatra_call.params,
        :logger       => sinatra_call.settings.logger,
        :router       => sinatra_call.settings.router,
        :session      => sinatra_call.session
      }
      runner = Deas::SinatraRunner.new(self.handler_class, args)

      sinatra_call.request.env.tap do |env|
        env['deas.params'] = runner.params
        env['deas.handler_class_name'] = self.handler_class.name
        env['deas.logging'].call "  Handler: #{env['deas.handler_class_name']}"
        env['deas.logging'].call "  Params:  #{env['deas.params'].inspect}"
      end
      runner.run
    end

  end

end

require 'deas/sinatra_runner'

module Deas
  class Route

    attr_reader :method, :path, :handler_proxy, :handler_class

    def initialize(method, path, handler_proxy)
      @method, @path, @handler_proxy = method, path, handler_proxy
    end

    def validate!
      @handler_class = @handler_proxy.handler_class
    end

    # TODO: unit test this??
    def run(sinatra_call)
      sinatra_call.request.env.tap do |env|
        env['sinatra.params']          = sinatra_call.params
        env['deas.handler_class_name'] = self.handler_class.name
        env['deas.logging'].call "  Handler: #{env['deas.handler_class_name']}"
        env['deas.logging'].call "  Params:  #{env['sinatra.params'].inspect}"
      end
      Deas::SinatraRunner.run(self.handler_class, sinatra_call)
    end

  end
end

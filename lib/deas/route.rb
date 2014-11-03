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
      args = {
        :sinatra_call => sinatra_call
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

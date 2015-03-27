require 'deas/exceptions'
require 'deas/sinatra_runner'

module Deas

  class HandlerProxy

    attr_reader :handler_class_name, :handler_class

    def initialize(handler_class_name)
      @handler_class_name = handler_class_name
    end

    def validate!
      raise NotImplementedError
    end

    def run(sinatra_call)
      runner = SinatraRunner.new(self.handler_class, {
        :sinatra_call => sinatra_call,
        :request      => sinatra_call.request,
        :response     => sinatra_call.response,
        :session      => sinatra_call.session,
        :params       => sinatra_call.params,
        :logger       => sinatra_call.settings.logger,
        :router       => sinatra_call.settings.router,
        :template_source => sinatra_call.settings.template_source
      })

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

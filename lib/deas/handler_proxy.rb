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

    def run(server_data, sinatra_call)
      runner = SinatraRunner.new(self.handler_class, {
        :sinatra_call    => sinatra_call,
        :request         => sinatra_call.request,
        :session         => sinatra_call.session,
        :params          => sinatra_call.params,
        :logger          => server_data.logger,
        :router          => server_data.router,
        :template_source => server_data.template_source
      })

      runner.request.env.tap do |env|
        # make runner data available to Rack (ie middlewares)
        # this is specifically needed by the Logging middleware
        # this is also needed by the Sinatra error handlers so they can provide
        # error context.  This may change when we eventually remove Sinatra.
        env['deas.handler_class'] = self.handler_class
        env['deas.handler']       = runner.handler
        env['deas.params']        = runner.params

        # this handles the verbose logging (it is a no-op if summary logging)
        env['deas.logging'].call "  Handler: #{self.handler_class.name}"
        env['deas.logging'].call "  Params:  #{runner.params.inspect}"
      end

      runner.run
    end

  end

end

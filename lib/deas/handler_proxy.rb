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

    def run(server_data, sinatra_call)
      # captures are not part of Deas' intended behavior and route matching
      # they are a side-effects of using Sinatra.  remove them so they won't
      # be relied upon in Deas apps.
      sinatra_call.params.delete(:captures)
      sinatra_call.params.delete('captures')

      # splat will be provided to the handlers via a special `splat` helper.
      # only single splat values are allowed (see router `url` method).  this
      # takes the last splat value from Sinatra and provides it standalone to
      # the runner.
      splat_sym_param    = sinatra_call.params.delete(:splat)
      splat_string_param = sinatra_call.params.delete('splat')
      splat_value        = (splat_sym_param || splat_string_param || []).last

      runner = DeasRunner.new(self.handler_class, {
        :logger          => server_data.logger,
        :router          => server_data.router,
        :template_source => server_data.template_source,
        :request         => sinatra_call.request,
        :session         => sinatra_call.session,
        :params          => sinatra_call.params,
        :splat           => splat_value
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
        env['deas.logging'].call "  Splat:   #{runner.splat.inspect}" if !runner.splat.nil?
      end

      runner.run
    end

  end

end

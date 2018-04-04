require 'sinatra/base'
require 'timeout'
require 'deas/error_handler'
require 'deas/exceptions'
require 'deas/request_data'
require 'deas/server_data'

module Deas

  module SinatraApp

    DEFAULT_ERROR_RESPONSE_STATUS = 500.freeze

    # these are standard error classes that we rescue, handle and don't reraise
    # in the rack app, this keeps the app from shutting down unexpectedly;
    # `LoadError`, `NotImplementedError` and `Timeout::Error` are common non
    # `StandardError` exceptions that should be treated like a `StandardError`
    # so we don't want one of these to shutdown the app
    STANDARD_ERROR_CLASSES = [
      StandardError,
      LoadError,
      NotImplementedError,
      Timeout::Error
    ].freeze

    def self.new(server_config)
      # This is generic server initialization stuff.  Eventually do this in the
      # server's initialization logic more like Sanford does.
      server_config.validate!
      server_data = ServerData.new({
        :error_procs            => server_config.error_procs,
        :before_route_run_procs => server_config.before_route_run_procs,
        :after_route_run_procs  => server_config.after_route_run_procs,
        :logger                 => server_config.logger,
        :router                 => server_config.router,
        :template_source        => server_config.template_source
      })

      Sinatra.new do
        # unifying settings - these are used by Deas so extensions can have a
        # common way to identify these low-level settings.  Deas does not use
        # them directly
        set :environment, server_config.env
        set :root,        server_config.root

        # TODO: sucks to have to do this but b/c of Rack there is no better way
        # to make the server data available to middleware.  We should remove this
        # once we remove Sinatra.  Whatever rack app implemenation will needs to
        # provide the server data or maybe the server data *will be* the rack app.
        # Not sure right now, just jotting down notes.
        set :deas_server_data, server_data

        # static settings - Deas doesn't care about these anymore so just
        # use some intelligent defaults
        set :views,            server_config.root
        set :public_folder,    server_config.root
        set :default_encoding, 'utf-8'
        set :method_override,  false
        set :reload_templates, false
        set :static,           false
        set :sessions,         false

        # Turn this off b/c Deas won't auto provide it.  We may add an extension
        # gem or something??
        disable :protection

        # raise_errors and show_exceptions prevent Deas error handlers from being
        # called and Deas' logging doesn't finish. They should always be false.
        set :raise_errors,     false
        set :show_exceptions,  false

        # turn off logging, dump_errors b/c Deas handles its own logging logic
        set :dump_errors,      false
        set :logging,          false

        server_config.middlewares.each{ |use_args| use *use_args }

        # routes
        server_config.routes.each do |route|
          send(route.method, route.path) do
            begin
              route.run(
                server_data,
                RequestData.new({
                  :request    => request,
                  :response   => response,
                  :params     => params,
                  :route_path => route.path
                })
              )
            rescue *STANDARD_ERROR_CLASSES => err
              request.env['deas.error'] = err
              response.status = DEFAULT_ERROR_RESPONSE_STATUS
              ErrorHandler.run(request.env['deas.error'], {
                :server_data   => server_data,
                :request       => request,
                :response      => response,
                :handler_class => request.env['deas.handler_class'],
                :handler       => request.env['deas.handler'],
                :params        => request.env['deas.params'],
                :splat         => request.env['deas.splat'],
                :route_path    => request.env['deas.route_path']
              })
            end
          end
        end

        not_found do
          # `self` is the sinatra call in this context
          if env['sinatra.error']
            env['deas.error'] = if env['sinatra.error'].instance_of?(::Sinatra::NotFound)
              Deas::NotFound.new(env['PATH_INFO']).tap do |e|
                e.set_backtrace(env['sinatra.error'].backtrace)
              end
            else
              env['sinatra.error']
            end
            ErrorHandler.run(env['deas.error'], {
              :server_data   => server_data,
              :request       => request,
              :response      => response,
              :handler_class => request.env['deas.handler_class'],
              :handler       => request.env['deas.handler'],
              :params        => request.env['deas.params'],
              :splat         => request.env['deas.splat'],
              :route_path    => request.env['deas.route_path']
            })
          end
        end

      end
    end

  end

end

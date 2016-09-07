require 'sinatra/base'
require 'deas/error_handler'
require 'deas/exceptions'
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
        :error_procs     => server_config.error_procs,
        :logger          => server_config.logger,
        :router          => server_config.router,
        :template_source => server_config.template_source
      })

      Sinatra.new do
        # built-in settings
        set :environment,      server_config.env
        set :root,             server_config.root
        set :views,            server_config.views_root
        set :public_folder,    server_config.public_root
        set :default_encoding, server_config.default_encoding
        set :dump_errors,      server_config.dump_errors
        set :method_override,  server_config.method_override
        set :reload_templates, server_config.reload_templates
        set :static,           server_config.static_files
        set :sessions,         false

        # TODO: sucks to have to do this but b/c of Rack there is no better way
        # to make the server data available to middleware.  We should remove this
        # once we remove Sinatra.  Whatever rack app implemenation will needs to
        # provide the server data or maybe the server data *will be* the rack app.
        # Not sure right now, just jotting down notes.
        set :deas_server_data, server_data

        # raise_errors and show_exceptions prevent Deas error handlers from being
        # called and Deas' logging doesn't finish. They should always be false.
        set :raise_errors,     false
        set :show_exceptions,  false

        # turn off logging b/c Deas handles its own logging logic
        set :logging,          false

        # TODO: rework with `server_config.default_encoding` once we move off of using Sinatra
        # TODO: could maybe move into a deas-json mixin once off of Sinatra
        # Add charset to json content type responses - by default only added to these:
        # ["application/javascript", "application/xml", "application/xhtml+xml", /^text\//]
        settings.add_charset << "application/json"

        server_config.settings.each{ |set_args| set *set_args }
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
                :route_path    => request.env['deas.route_path']
              })
            end
          end
        end

        # error handling

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
              :request       => self.request,
              :response      => self.response,
              :handler_class => self.request.env['deas.handler_class'],
              :handler       => self.request.env['deas.handler'],
              :params        => self.request.env['deas.params'],
            })
          end
        end

      end
    end

  end

end

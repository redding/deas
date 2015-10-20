require 'sinatra/base'
require 'deas/error_handler'
require 'deas/exceptions'
require 'deas/server_data'

module Deas

  module SinatraApp

    def self.new(server_config)
      # This is generic server initialization stuff.  Eventually do this in the
      # server's initialization logic more like Sanford does.
      server_config.validate!
      server_data = ServerData.new(server_config.to_hash)

      Sinatra.new do
        # built-in settings
        set :environment,      server_config.env
        set :root,             server_config.root
        set :public_folder,    server_config.public_root
        set :views,            server_config.views_root
        set :dump_errors,      server_config.dump_errors
        set :method_override,  server_config.method_override
        set :sessions,         server_config.sessions
        set :static,           server_config.static_files
        set :reload_templates, server_config.reload_templates
        set :default_encoding, server_config.default_encoding
        set :logging,          false

        # TODO: sucks to have to do this but b/c or Rack there is no better way
        # to make the server data available to middleware.  We should remove this
        # once we remove Sinatra.  Whatever rack app implemenation will needs to
        # provide the server data or maybe the server data *will be* the rack app.
        # Not sure right now, just jotting down notes.
        set :deas_server_data, server_data

        # raise_errors and show_exceptions prevent Deas error handlers from being
        # called and Deas' logging doesn't finish. They should always be false.
        set :raise_errors,     false
        set :show_exceptions,  false

        # TODO: rework with `server_config.default_encoding` once we move off of using Sinatra
        # TODO: could maybe move into a deas-json mixin once off of Sinatra
        # Add charset to json content type responses - by default only added to these:
        # ["application/javascript", "application/xml", "application/xhtml+xml", /^text\//]
        settings.add_charset << "application/json"

        server_config.settings.each{ |set_args| set *set_args }
        server_config.middlewares.each{ |use_args| use *use_args }

        # routes
        server_config.routes.each do |route|
          # TODO: `self` is the sinatra_call; eventually stop sending it
          # (part of phasing out Sinatra)
          send(route.method, route.path){ route.run(server_data, self) }
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
        error do
          # `self` is the sinatra call in this context
          if env['sinatra.error']
            env['deas.error'] = env['sinatra.error']
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

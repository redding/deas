require 'sinatra/base'
require 'deas/error_handler'

module Deas
  module SinatraApp

    def self.new(server_config)
      server_config.validate!

      Sinatra.new do

        # built-in settings
        set :environment, server_config.env
        set :root,        server_config.root

        set :public_folder, server_config.public_folder
        set :views,         server_config.views_folder

        set :dump_errors,      server_config.dump_errors
        set :method_override,  server_config.method_override
        set :sessions,         server_config.sessions
        set :static,           server_config.static_files
        set :reload_templates, server_config.reload_templates
        set :logging,          false

        # raise_errors and show_exceptions prevent Deas error handlers from
        # being called and Deas' logging doesn't finish. They should always be
        # false.
        set :raise_errors,     false
        set :show_exceptions,  false

        # custom settings
        set :deas_template_scope,  server_config.template_scope
        set :deas_error_procs,     server_config.error_procs
        set :deas_default_charset, server_config.default_charset
        set :logger,               server_config.logger

        server_config.settings.each{ |set_args| set *set_args }
        server_config.middlewares.each{ |use_args| use *use_args }

        # routes
        server_config.routes.each do |route|
          send(route.method, route.path){ route.run(self) }
        end

        # error handling
        not_found do
          env['sinatra.error'] ||= Sinatra::NotFound.new
          ErrorHandler.run(env['sinatra.error'], self, settings.deas_error_procs)
        end
        error do
          ErrorHandler.run(env['sinatra.error'], self, settings.deas_error_procs)
        end

      end
    end

  end
end

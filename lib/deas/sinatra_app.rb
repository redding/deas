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
        set :show_exceptions,  server_config.show_exceptions
        set :static,           server_config.static_files
        set :reload_templates, server_config.reload_templates
        set :logging,          false

        # custom settings
        set :deas_template_scope, server_config.template_scope
        set :deas_error_procs,    server_config.error_procs
        set :logger,              server_config.logger

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

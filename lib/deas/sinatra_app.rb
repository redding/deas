require 'sinatra/base'
require 'deas/error_handler'
require 'deas/logging'

module Deas

  module SinatraApp

    def self.new(server_config)
      server_config.init_proc.call
      server_config.routes.each(&:constantize!)

      Sinatra.new do

        # built-in settings
        set :environment, server_config.env
        set :root,        server_config.root

        set :app_file,      server_config.app_file
        set :public_folder, server_config.public_folder
        set :views,         server_config.views_folder

        set :dump_errors,      server_config.dump_errors
        set :method_override,  server_config.method_override
        set :sessions,         server_config.sessions
        set :show_exceptions,  server_config.show_exceptions
        set :static,           server_config.static_files
        set :reload_templates, server_config.reload_templates
        set :logging,         false

        # custom settings
        set :deas_error_procs, server_config.error_procs
        set :logger,           server_config.logger

        server_config.middlewares.each do |middleware_args|
          use *middleware_args
        end
        use Deas::Logging.middleware(server_config.verbose_logging)

        # routes
        server_config.routes.each do |route|
          # defines Sinatra routes like:
          #   get('/'){ ... }
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

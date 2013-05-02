require 'sinatra/base'

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

        set :dump_errors,     server_config.dump_errors
        set :logging,         false
        set :method_override, server_config.method_override
        set :sessions,        server_config.sessions
        set :show_exceptions, server_config.show_exceptions
        set :static,          server_config.static_files

        # custom settings
        set :logger,        server_config.logger
        set :runner_logger, server_config.runner_logger

        server_config.middlewares.each do |middleware_args|
          use *middleware_args
        end

        # routes
        server_config.routes.each do |route|
          # defines Sinatra routes like:
          #   before('/'){ ... }
          #   get('/'){ ... }
          #   after('/'){ ... }
          before(route.path) do
            @runner = route.runner(self).setup
          end
          send(route.method, route.path) do
            @runner.run
          end
          after(route.path) do
            @runner.teardown
          end
        end

      end
    end

  end

end

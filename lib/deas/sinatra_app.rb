require 'sinatra/base'

module Deas

  module SinatraApp

    def self.new(server_config)
      server_config.init_proc.call

      Class.new(Sinatra::Base).tap do |app|

        app.set :environment, server_config.env
        app.set :root,        server_config.root

        app.set :app_file,      server_config.app_file
        app.set :public_folder, server_config.public_folder
        app.set :views,         server_config.views_folder

        app.set :dump_errors,     server_config.dump_errors
        app.set :logging,         false
        app.set :method_override, server_config.method_override
        app.set :sessions,        server_config.sessions
        app.set :static,          server_config.static_files

      end
    end

  end

end

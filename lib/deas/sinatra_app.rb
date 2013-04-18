require 'sinatra/base'

module Deas

  module SinatraApp

    def self.new(server_config)
      server_config.init_proc.call

      Class.new(Sinatra::Base)
    end

  end

end

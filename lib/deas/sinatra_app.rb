require 'sinatra/base'

module Deas

  module SinatraApp

    def self.new(server)
      Class.new(Sinatra::Base)
    end

  end

end

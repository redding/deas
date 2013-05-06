require 'ns-options'
require 'pathname'

require 'deas/version'
require 'deas/server'
require 'deas/sinatra_app'
require 'deas/view_handler'

# TODO - remove with future version of Rack (> v1.5.2)
require 'deas/rack_request_fix'

ENV['DEAS_ROUTES_FILE'] ||= 'config/routes'

module Deas

  def self.app
    @app
  end

  def self.config
    Deas::Config
  end

  def self.configure(&block)
    self.config.define(&block)
    self.config
  end

  def self.init
    require self.config.routes_file
    @app = Deas::SinatraApp.new(Deas::Server.configuration)
  end

  module Config
    include NsOptions::Proxy
    option :routes_file,  Pathname, :default => ENV['DEAS_ROUTES_FILE']
  end

  class NullLogger
    require 'logger'

    ::Logger::Severity.constants.each do |name|
      define_method(name.downcase){|*args| } # no-op
    end
  end

end

require 'ns-options'
require 'pathname'

require 'deas/server'
require 'deas/sinatra_app'
require 'deas/version'

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
    @app = Deas::SinatraApp.new(Deas::Server)
  end

  module Config
    include NsOptions::Proxy
    option :routes_file,  Pathname, :default => ENV['DEAS_ROUTES_FILE']
  end

end

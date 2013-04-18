require 'ns-options'
require 'singleton'

module Deas

  class Server
    include Singleton

    class Configuration
      include NsOptions::Proxy

      option :init_proc, Proc, :default => proc{ }

    end

    attr_reader :configuration

    def initialize
      @configuration = Configuration.new
    end

    def init(&block)
      self.configuration.init_proc = block
    end

    def self.method_missing(method, *args, &block)
      self.instance.send(method, *args, &block)
    end

    def self.respond_to?(*args)
      super || self.instance.respond_to?(*args)
    end

  end

end

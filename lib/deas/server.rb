require 'ns-options'
require 'ns-options/boolean'
require 'pathname'
require 'singleton'

module Deas

  class Server
    include Singleton

    class Configuration
      include NsOptions::Proxy

      option :env,  String,   :default => 'development'
      option :root, Pathname, :default => proc{ File.dirname(Deas.config.routes_file) }

      option :app_file,      Pathname, :default => proc{ Deas.config.routes_file }
      option :public_folder, Pathname
      option :views_folder,  Pathname

      option :dump_errors,     NsOptions::Boolean, :default => false
      option :method_override, NsOptions::Boolean, :default => true
      option :sessions,        NsOptions::Boolean, :default => true
      option :static_files,    NsOptions::Boolean, :default => true

      option :init_proc, Proc,   :default => proc{ }

      def initialize
        super
        # these are defaulted here because we want to use the Configuration
        # instance `root`. If we define a proc above, we will be using the
        # Configuration class `root`, which will not update these options as
        # expected.
        self.public_folder = proc{ self.root.join('public') }
        self.views_folder  = proc{ self.root.join('views') }
      end

    end

    attr_reader :configuration

    def initialize
      @configuration = Configuration.new
    end

    def env(*args)
      self.configuration.env *args
    end

    def root(*args)
      self.configuration.root *args
    end

    def public_folder(*args)
      self.configuration.root *args
    end

    def views_folder(*args)
      self.configuration.root *args
    end

    def dump_errors(*args)
      self.configuration.dump_errors *args
    end

    def method_override(*args)
      self.configuration.method_override *args
    end

    def sessions(*args)
      self.configuration.sessions *args
    end

    def static_files(*args)
      self.configuration.static_files *args
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

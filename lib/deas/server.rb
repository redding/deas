require 'ns-options'
require 'ns-options/boolean'
require 'pathname'
require 'singleton'
require 'deas/route'

module Deas

  class Server
    include Singleton

    class Configuration
      include NsOptions::Proxy

      # Sinatra based options
      option :env,  String,   :default => 'development'
      option :root, Pathname, :default => proc{ File.dirname(Deas.config.routes_file) }

      option :app_file,      Pathname, :default => proc{ Deas.config.routes_file }
      option :public_folder, Pathname
      option :views_folder,  Pathname

      option :dump_errors,      NsOptions::Boolean, :default => false
      option :method_override,  NsOptions::Boolean, :default => true
      option :sessions,         NsOptions::Boolean, :default => true
      option :show_exceptions,  NsOptions::Boolean, :default => false
      option :static_files,     NsOptions::Boolean, :default => true

      # server handling options
      option :init_proc,       Proc,  :default => proc{ }
      option :logger,                 :default => proc{ Deas::NullLogger.new }
      option :middlewares,     Array, :default => []
      option :verbose_logging,        :default => true

      option :routes,          Array, :default => []
      option :view_handler_ns, String

      def initialize
        # these are defaulted here because we want to use the Configuration
        # instance `root`. If we define a proc above, we will be using the
        # Configuration class `root`, which will not update these options as
        # expected.
        super({
          :public_folder => proc{ self.root.join('public') },
          :views_folder  => proc{ self.root.join('views') }
        })
      end

    end

    attr_reader :configuration

    def initialize
      @configuration = Configuration.new
    end

    # sinatra settings DSL

    def env(*args)
      self.configuration.env *args
    end

    def root(*args)
      self.configuration.root *args
    end

    def public_folder(*args)
      self.configuration.public_folder *args
    end

    def views_folder(*args)
      self.configuration.views_folder *args
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

    def show_exceptions(*args)
      self.configuration.show_exceptions *args
    end

    def static_files(*args)
      self.configuration.static_files *args
    end

    # Server handling DSL

    def init(&block)
      self.configuration.init_proc = block
    end

    def logger(*args)
      self.configuration.logger *args
    end

    def verbose_logging(*args)
      self.configuration.verbose_logging *args
    end

    def view_handler_ns(*args)
      self.configuration.view_handler_ns *args
    end

    def use(*args)
      self.configuration.middlewares << args
    end

    def get(path, handler_class_name)
      self.route(:get, path, handler_class_name)
    end

    def post(path, handler_class_name)
      self.route(:post, path, handler_class_name)
    end

    def put(path, handler_class_name)
      self.route(:put, path, handler_class_name)
    end

    def patch(path, handler_class_name)
      self.route(:patch, path, handler_class_name)
    end

    def delete(path, handler_class_name)
      self.route(:delete, path, handler_class_name)
    end

    def route(http_method, path, handler_class_name)
      if self.view_handler_ns && !(handler_class_name =~ /^::/)
        handler_class_name = "#{self.view_handler_ns}::#{handler_class_name}"
      end
      Deas::Route.new(http_method, path, handler_class_name).tap do |route|
        self.configuration.routes.push(route)
      end
    end

    def self.method_missing(method, *args, &block)
      self.instance.send(method, *args, &block)
    end

    def self.respond_to?(*args)
      super || self.instance.respond_to?(*args)
    end

  end

end

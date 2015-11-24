require 'much-plugin'
require 'ns-options'
require 'ns-options/boolean'
require 'pathname'
require 'deas/exceptions'
require 'deas/logger'
require 'deas/logging'
require 'deas/router'
require 'deas/show_exceptions'
require 'deas/sinatra_app'
require 'deas/template_source'

module Deas

  module Server
    include MuchPlugin

    plugin_included do
      extend ClassMethods
      include InstanceMethods
    end

    module InstanceMethods

      # TODO: once Deas is no longer powered by Sinatra, this should define an
      # `initialize` method that builds a server instance.  Right now there is
      # a `new` class method that builds a SinatraApp which does this init
      # behavior

    end

    module ClassMethods

      # TODO: needed while Deas is powered by Sinatra
      # eventually do an initialize method more like Sanford does
      def new
        Deas::SinatraApp.new(self.configuration)
      end

      def configuration
        @configuration ||= Configuration.new
      end

      # sinatra settings DSL

      def env(*args)
        self.configuration.env *args
      end

      def root(*args)
        self.configuration.root *args
      end

      def public_root(*args)
        self.configuration.public_root *args
      end

      def views_root(*args)
        self.configuration.views_root *args
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

      def reload_templates(*args)
        self.configuration.reload_templates *args
      end

      # Server handling DSL

      def init(&block)
        self.configuration.init_procs << block
      end

      def error(&block)
        self.configuration.error_procs << block
      end

      def template_helpers(*helper_modules)
        helper_modules.each{ |m| self.configuration.template_helpers << m }
        self.configuration.template_helpers
      end

      def template_helper?(helper_module)
        self.configuration.template_helpers.include?(helper_module)
      end

      def use(*args)
        self.configuration.middlewares << args
      end

      def set(name, value)
        self.configuration.settings[name.to_sym] = value
      end

      def verbose_logging(*args)
        self.configuration.verbose_logging *args
      end

      def logger(*args)
        self.configuration.logger *args
      end

      def default_encoding(*args)
        self.configuration.default_encoding *args
      end

      def template_source(*args)
        self.configuration.template_source *args
      end

      # router handling

      def router(value = nil)
        self.configuration.router = value if !value.nil?
        self.configuration.router
      end

      def view_handler_ns(*args); self.router.view_handler_ns(*args); end
      def base_url(*args);        self.router.base_url(*args);        end

      def url(*args, &block);     self.router.url(*args, &block);     end
      def url_for(*args, &block); self.router.url_for(*args, &block); end

      def default_request_type_name(*args); self.router.default_request_type_name(*args); end
      def add_request_type(*args, &block);  self.router.add_request_type(*args, &block);  end
      def request_type_name(*args);         self.router.request_type_name(*args);         end

      def get(*args, &block);    self.router.get(*args, &block);    end
      def post(*args, &block);   self.router.post(*args, &block);   end
      def put(*args, &block);    self.router.put(*args, &block);    end
      def patch(*args, &block);  self.router.patch(*args, &block);  end
      def delete(*args, &block); self.router.delete(*args, &block); end

      def route(*args, &block);    self.router.route(*args, &block);    end
      def redirect(*args, &block); self.router.redirect(*args, &block); end

    end

    class Configuration
      include NsOptions::Proxy

      # Sinatra-based options

      option :env,  String,   :default => 'development'

      option :root,        Pathname, :required => true
      option :public_root, Pathname
      option :views_root,  Pathname

      option :dump_errors,      NsOptions::Boolean, :default => false
      option :method_override,  NsOptions::Boolean, :default => true
      option :sessions,         NsOptions::Boolean, :default => false
      option :show_exceptions,  NsOptions::Boolean, :default => false
      option :static_files,     NsOptions::Boolean, :default => true
      option :reload_templates, NsOptions::Boolean, :default => false
      option :default_encoding, String,             :default => 'utf-8'

      # server handling options

      option :verbose_logging, NsOptions::Boolean, :default => true
      option :logger
      option :template_source

      attr_accessor :settings, :init_procs, :error_procs, :template_helpers
      attr_accessor :middlewares, :router

      def initialize(values = nil)
        # these are defaulted here because we want to use the Configuration
        # instance `root`. If we define a proc above, we will be using the
        # Configuration class `root`, which will not update these options as
        # expected.
        super((values || {}).merge({
          :public_root     => proc{ self.root.join('public') },
          :views_root      => proc{ self.root.join('views') },
          :logger          => proc{ Deas::NullLogger.new },
          :template_source => proc{ Deas::NullTemplateSource.new(self.root) }
        }))
        @settings = {}
        @init_procs, @error_procs, @template_helpers, @middlewares = [], [], [], []
        @router = Deas::Router.new
        @valid  = nil
      end

      def urls
        self.router.urls
      end

      def routes
        self.router.routes
      end

      def to_hash
        super.merge({
          :error_procs => self.error_procs,
          :router      => self.router
        })
      end

      def valid?
        !!@valid
      end

      # for the config to be considered "valid", a few things need to happen.  The
      # key here is that this only needs to be done _once_ for each config.

      def validate!
        return @valid if !@valid.nil?  # only need to run this once per config

        # ensure all user and plugin configs/settings are applied
        self.init_procs.each{ |p| p.call }
        raise Deas::ServerRootError if self.root.nil?

        # validate the router
        self.router.validate!

        # append the show exceptions and logging middlewares last.  This ensures
        # that the logging and exception showing happens just before the app gets
        # the request and just after the app sends a response.
        self.middlewares << [Deas::ShowExceptions] if self.show_exceptions
        [*Deas::Logging.middleware(self.verbose_logging)].tap do |mw_args|
          self.middlewares << mw_args
        end

        @valid = true  # if it made it this far, its valid!
      end

    end

  end

end

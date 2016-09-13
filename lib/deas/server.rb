require 'much-plugin'
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
        begin
          Deas::SinatraApp.new(self.config)
        rescue Router::InvalidSplatError => e
          # reset the exception backtrace to hide Deas internals
          raise e.class, e.message, caller
        end
      end

      def config
        @config ||= Config.new
      end

      def env(value = nil)
        self.config.env = value if !value.nil?
        self.config.env
      end

      def root(value = nil)
        self.config.root = value if !value.nil?
        self.config.root
      end

      def method_override(value = nil)
        self.config.method_override = value if !value.nil?
        self.config.method_override
      end

      def show_exceptions(value = nil)
        self.config.show_exceptions = value if !value.nil?
        self.config.show_exceptions
      end

      def verbose_logging(value = nil)
        self.config.verbose_logging = value if !value.nil?
        self.config.verbose_logging
      end

      def use(*args)
        self.config.middlewares << args
      end

      def middlewares
        self.config.middlewares
      end

      def init(&block)
        self.config.init_procs << block
      end

      def init_procs
        self.config.init_procs
      end

      def error(&block)
        self.config.error_procs << block
      end

      def error_procs
        self.config.error_procs
      end

      def template_source(value = nil)
        self.config.template_source = value if !value.nil?
        self.config.template_source
      end

      def logger(value = nil)
        self.config.logger = value if !value.nil?
        self.config.logger
      end

      # router handling

      def router(value = nil, &block)
        self.config.router = value if !value.nil?
        self.config.router.instance_eval(&block) if block
        self.config.router
      end

      def url_for(*args, &block); self.router.url_for(*args, &block); end

    end

    class Config

      DEFAULT_ENV = 'development'.freeze

      attr_accessor :env, :root
      attr_accessor :method_override, :show_exceptions, :verbose_logging
      attr_accessor :middlewares, :init_procs, :error_procs
      attr_accessor :template_source, :logger, :router

      def initialize
        @env             = DEFAULT_ENV
        @root            = ENV['PWD']
        @method_override = true
        @show_exceptions = false
        @verbose_logging = true
        @middlewares     = []
        @init_procs      = []
        @error_procs     = []
        @template_source = nil
        @logger          = Deas::NullLogger.new
        @router          = Deas::Router.new

        @valid = nil
      end

      def template_source
        @template_source ||= Deas::NullTemplateSource.new(self.root)
      end

      def urls
        self.router.urls
      end

      def routes
        self.router.routes
      end

      def valid?
        !!@valid
      end

      # for the config to be considered "valid", a few things need to happen.
      # The key here is that this only needs to be done _once_ for each config.

      def validate!
        return @valid if !@valid.nil?  # only need to run this once per config

        # ensure all user and plugin configs are applied
        self.init_procs.each(&:call)
        raise Deas::ServerRootError if self.root.nil?

        # validate the router
        self.router.validate!

        # TODO: build final middleware stack when building the rack app, not here
        # (once Sinatra is removed)

        # prepend the method override middleware first.  This ensures that the
        # it is run before any other middleware
        self.middlewares.unshift([Rack::MethodOverride]) if self.method_override

        # append the show exceptions and logging middlewares last.  This ensures
        # that the logging and exception showing happens just before the app gets
        # the request and just after the app sends a response.
        self.middlewares << [Deas::ShowExceptions] if self.show_exceptions
        self.middlewares << Deas::Logging.middleware_args(self.verbose_logging)
        self.middlewares.freeze

        @valid = true # if it made it this far, its valid!
      end

    end

  end

end

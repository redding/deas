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
        Deas::SinatraApp.new(self.config)
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

      def views_path(value = nil)
        self.config.views_path = value if !value.nil?
        self.config.views_path
      end

      def public_path(value = nil)
        self.config.public_path = value if !value.nil?
        self.config.public_path
      end

      def default_encoding(value = nil)
        self.config.default_encoding = value if !value.nil?
        self.config.default_encoding
      end

      def set(name, value)
        self.config.settings[name.to_sym] = value
      end

      def template_helpers(*helper_modules)
        helper_modules.each{ |m| self.config.template_helpers << m }
        self.config.template_helpers
      end

      def template_helper?(helper_module)
        self.config.template_helpers.include?(helper_module)
      end

      def use(*args)
        self.config.middlewares << args
      end

      def init(&block)
        self.config.init_procs << block
      end

      def error(&block)
        self.config.error_procs << block
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

      # flags

      def dump_errors(value = nil)
        self.config.dump_errors = value if !value.nil?
        self.config.dump_errors
      end

      def method_override(value = nil)
        self.config.method_override = value if !value.nil?
        self.config.method_override
      end

      def reload_templates(value = nil)
        self.config.reload_templates = value if !value.nil?
        self.config.reload_templates
      end

      def sessions(value = nil)
        self.config.sessions = value if !value.nil?
        self.config.sessions
      end

      def show_exceptions(value = nil)
        self.config.show_exceptions = value if !value.nil?
        self.config.show_exceptions
      end

      def static_files(value = nil)
        self.config.static_files = value if !value.nil?
        self.config.static_files
      end

      def verbose_logging(value = nil)
        self.config.verbose_logging = value if !value.nil?
        self.config.verbose_logging
      end

    end

    class Config

      DEFAULT_ENV         = 'development'.freeze
      DEFAULT_VIEWS_PATH  = 'views'.freeze
      DEFAULT_PUBLIC_PATH = 'public'.freeze
      DEFAULT_ENCODING    = 'utf-8'.freeze

      attr_accessor :env, :root, :views_path, :public_path, :default_encoding
      attr_accessor :settings, :template_helpers, :middlewares
      attr_accessor :init_procs, :error_procs, :template_source, :logger, :router

      attr_accessor :dump_errors, :method_override, :reload_templates
      attr_accessor :sessions, :show_exceptions, :static_files
      attr_accessor :verbose_logging

      def initialize
        @env              = DEFAULT_ENV
        @root             = ENV['PWD']
        @views_path       = DEFAULT_VIEWS_PATH
        @public_path      = DEFAULT_PUBLIC_PATH
        @default_encoding = DEFAULT_ENCODING
        @settings         = {}
        @template_helpers = []
        @middlewares      = []
        @init_procs       = []
        @error_procs      = []
        @template_source  = nil
        @logger           = Deas::NullLogger.new
        @router           = Deas::Router.new

        @dump_errors      = false
        @method_override  = true
        @reload_templates = false
        @sessions         = false
        @show_exceptions  = false
        @static_files     = true
        @verbose_logging  = true

        @valid = nil
      end

      def views_root
        File.expand_path(@views_path.to_s, @root.to_s)
      end

      def public_root
        File.expand_path(@public_path.to_s, @root.to_s)
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

        # ensure all user and plugin configs/settings are applied
        self.init_procs.each(&:call)
        raise Deas::ServerRootError if self.root.nil?

        # validate the router
        self.router.validate!

        # append the show exceptions and logging middlewares last.  This ensures
        # that the logging and exception showing happens just before the app gets
        # the request and just after the app sends a response.
        self.middlewares << [Deas::ShowExceptions] if self.show_exceptions
        logging_mw_args = [*Deas::Logging.middleware(self.verbose_logging)]
        self.middlewares << logging_mw_args

        @valid = true # if it made it this far, its valid!
      end

    end

  end

end

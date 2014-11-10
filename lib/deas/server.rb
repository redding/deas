require 'pathname'
require 'ns-options'
require 'ns-options/boolean'
require 'deas/exceptions'
require 'deas/logger'
require 'deas/logging'
require 'deas/router'
require 'deas/sinatra_app'
require 'deas/show_exceptions'
require 'deas/template'
require 'deas/template_source'

module Deas; end
module Deas::Server

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
    option :default_charset,  String,             :default => 'utf-8'

    # server handling options

    option :verbose_logging, NsOptions::Boolean, :default => true
    option :logger,                              :default => proc{ Deas::NullLogger.new }
    option :template_source,                     :default => proc{ Deas::NullTemplateSource.new }

    attr_accessor :settings, :error_procs, :init_procs, :template_helpers
    attr_accessor :middlewares, :router

    def initialize(values = nil)
      # these are defaulted here because we want to use the Configuration
      # instance `root`. If we define a proc above, we will be using the
      # Configuration class `root`, which will not update these options as
      # expected.
      super((values || {}).merge({
        :public_root => proc{ self.root.join('public') },
        :views_root  => proc{ self.root.join('views') }
      }))
      @settings = {}
      @error_procs, @init_procs, @template_helpers, @middlewares = [], [], [], []
      @router = Deas::Router.new
      @valid = nil
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

      # validate the routes
      self.routes.each(&:validate!)

      # set the :erb :outvar setting if it hasn't been set.  this is used
      # by template helpers and plugins and needs to be queryable.  the actual
      # value doesn't matter - it just needs to be set
      self.settings[:erb] ||= {}
      self.settings[:erb][:outvar] ||= '@_out_buf'

      # append the show exceptions and loggine middlewares last.  This ensures
      # that the logging and exception showing happens just before the app gets
      # the request and just after the app sends a response.
      self.middlewares << [Deas::ShowExceptions] if self.show_exceptions
      [*Deas::Logging.middleware(self.verbose_logging)].tap do |mw_args|
        self.middlewares << mw_args
      end

      @valid = true  # if it made it this far, its valid!
    end

    def urls
      self.router.urls
    end

    def routes
      self.router.routes
    end

    def template_scope
      Class.new(Deas::Template::Scope).tap do |klass|
        klass.send(:include, *self.template_helpers)
      end
    end

  end

  def self.included(receiver)
    receiver.class_eval{ extend ClassMethods }
  end

  module ClassMethods

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

    def default_charset(*args)
      self.configuration.default_charset *args
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

    def get(*args, &block);    self.router.get(*args, &block);    end
    def post(*args, &block);   self.router.post(*args, &block);   end
    def put(*args, &block);    self.router.put(*args, &block);    end
    def patch(*args, &block);  self.router.patch(*args, &block);  end
    def delete(*args, &block); self.router.delete(*args, &block); end

    def route(*args, &block);    self.router.route(*args, &block);    end
    def redirect(*args, &block); self.router.redirect(*args, &block); end

  end

end

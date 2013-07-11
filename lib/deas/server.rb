require 'pathname'
require 'set'
require 'ns-options'
require 'ns-options/boolean'
require 'deas/exceptions'
require 'deas/template'
require 'deas/logging'
require 'deas/redirect_proxy'
require 'deas/route_proxy'
require 'deas/route'
require 'deas/url'
require 'deas/show_exceptions'
require 'deas/sinatra_app'

module Deas; end
module Deas::Server

  class Configuration
    include NsOptions::Proxy

    # Sinatra-based options

    option :env,  String,   :default => 'development'

    option :root,          Pathname, :required => true
    option :public_folder, Pathname
    option :views_folder,  Pathname

    option :dump_errors,      NsOptions::Boolean, :default => false
    option :method_override,  NsOptions::Boolean, :default => true
    option :sessions,         NsOptions::Boolean, :default => false
    option :show_exceptions,  NsOptions::Boolean, :default => false
    option :static_files,     NsOptions::Boolean, :default => true
    option :reload_templates, NsOptions::Boolean, :default => false
    option :default_charset,  String,             :default => 'utf-8'

    # server handling options

    option :logger,                              :default => proc{ Deas::NullLogger.new }
    option :verbose_logging, NsOptions::Boolean, :default => true
    option :view_handler_ns, String

    attr_accessor :settings, :error_procs, :init_procs, :template_helpers
    attr_accessor :middlewares, :routes, :urls

    def initialize(values=nil)
      # these are defaulted here because we want to use the Configuration
      # instance `root`. If we define a proc above, we will be using the
      # Configuration class `root`, which will not update these options as
      # expected.
      super((values || {}).merge({
        :public_folder => proc{ self.root.join('public') },
        :views_folder  => proc{ self.root.join('views') }
      }))
      @settings, @urls = {}, {}
      @error_procs, @init_procs, @template_helpers = [], [], []
      @middlewares, @routes = [], []
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

    def template_scope
      Class.new(Deas::Template::Scope).tap do |klass|
        klass.send(:include, *self.template_helpers)
      end
    end

    def add_route(http_method, path, proxy)
      Deas::Route.new(http_method, path, proxy).tap{ |r| self.routes.push(r) }
    end

    def add_url(name, path)
      self.urls[name] = Deas::Url.new(name, path)
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

    def view_handler_ns(*args)
      self.configuration.view_handler_ns *args
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

    def redirect(http_method, from_path, to_path = nil, &block)
      to_url = self.configuration.urls[to_path]
      if to_path.kind_of?(::Symbol) && to_url.nil?
        raise ArgumentError, "no url named `#{to_path.inspect}`"
      end
      proxy = Deas::RedirectProxy.new(to_url || to_path, &block)

      from_url = self.configuration.urls[from_path]
      from_url_path = from_url.path if from_url
      self.configuration.add_route(http_method, from_url_path || from_path, proxy)
    end

    def route(http_method, from_path, handler_class_name)
      if self.view_handler_ns && !(handler_class_name =~ /^::/)
        handler_class_name = "#{self.view_handler_ns}::#{handler_class_name}"
      end
      proxy = Deas::RouteProxy.new(handler_class_name)

      from_url = self.configuration.urls[from_path]
      from_url_path = from_url.path if from_url
      self.configuration.add_route(http_method, from_url_path || from_path, proxy)
    end

    def url(name, path)
      if !path.kind_of?(::String)
        raise ArgumentError, "invalid path `#{path.inspect}` - "\
                             "can only provide a url name with String paths"
      end
      self.configuration.add_url(name.to_sym, path)
    end

    def url_for(name, *args)
      url = self.configuration.urls[name.to_sym]
      raise ArgumentError, "no route named `#{name.to_sym.inspect}`" unless url

      url.path_for(*args)
    end

  end

end


require 'much-plugin'
require 'sinatra/base'
require 'deas/error_handler'
require 'deas/exceptions'
require 'deas/logger'
require 'deas/logging'
require 'deas/request_data'
require 'deas/router'
require 'deas/server_data'
require 'deas/show_exceptions'
require 'deas/sinatra_app'
require 'deas/template_source'

module Deas

  module Server
    include MuchPlugin

    DEFAULT_ERROR_RESPONSE_STATUS = 500.freeze

    # these are standard error classes that we rescue, handle and don't reraise
    # in the rack app, this keeps the app from shutting down unexpectedly;
    # `LoadError`, `NotImplementedError` and `Timeout::Error` are common non
    # `StandardError` exceptions that should be treated like a `StandardError`
    # so we don't want one of these to shutdown the app
    STANDARD_ERROR_CLASSES = [
      StandardError,
      LoadError,
      NotImplementedError,
      Timeout::Error
    ].freeze

    plugin_included do
      extend ClassMethods
      include InstanceMethods
    end

    module InstanceMethods

      attr_reader :deas_server_data

      def initialize(rack_builder)
        server_config = self.class.config

        begin
          server_config.validate!
        rescue Router::InvalidSplatError => e
          # reset the exception backtrace to hide Deas internals
          raise e.class, e.message, caller
        end

        @deas_server_data = ServerData.new({
          :environment     => server_config.env,
          :root            => server_config.root,
          :error_procs     => server_config.error_procs,
          :logger          => server_config.logger,
          :router          => server_config.router,
          :template_source => server_config.template_source
        })

        deas_build(server_config, rack_builder)
      end

      def call!(env)
        begin
          request = Rack::Request.new(env)
          route, params, splat = @deas_server_data.router_dispatch(request)
          route.run(
            @deas_server_data,
            RequestData.new({
              :request    => request,
              # :response   => response,
              :params     => params.merge(request.params),
              :splat      => splat,
              :route_path => route.path
            })
          )
          @deas_server_data.router_run(request)
        rescue [configured_not_found_errors] => err
          request.env['deas.error'] = Deas::NotFound.new(env['PATH_INFO'])
          request.env['deas.error'].set_backtrace(err.backtrace)
          ErrorHandler.run(request.env['deas.error'], {
            :server_data   => @deas_server_data,
            :request       => request,
            # :response      => response,
            :handler_class => request.env['deas.handler_class'],
            :handler       => request.env['deas.handler'],
            :params        => request.env['deas.params'],
            :splat         => request.env['deas.splat'],
            :route_path    => request.env['deas.route_path']
          })
          # return not found rack array
        rescue *STANDARD_ERROR_CLASSES => err
          request.env['deas.error'] = err
          # response.status = DEFAULT_ERROR_RESPONSE_STATUS
          ErrorHandler.run(request.env['deas.error'], {
            :server_data   => @deas_server_data,
            :request       => request,
            # :response      => response,
            :handler_class => request.env['deas.handler_class'],
            :handler       => request.env['deas.handler'],
            :params        => request.env['deas.params'],
            :splat         => request.env['deas.splat'],
            :route_path    => request.env['deas.route_path']
          })
          # return not found rack array
        end
      end

      private

      def deas_build(server_config, builder)
        # TODO: remove sinatra as a middleware and manually build middlewares
        deas_setup_sinatra_middleware(server_config, @deas_server_data, builder)
      end

      def deas_setup_sinatra_middleware(server_config, server_data, builder)
        builder.use Sinatra do
          # static settings - Deas doesn't care about these anymore so just
          # use some intelligent defaults
          set :environment,      server_config.env
          set :root,             server_config.root
          set :views,            server_config.root
          set :public_folder,    server_config.root
          set :default_encoding, 'utf-8'
          set :method_override,  false
          set :reload_templates, false
          set :static,           false
          set :sessions,         false

          # Turn this off b/c Deas won't auto provide it.
          disable :protection

          # raise_errors and show_exceptions prevent Deas error handlers from
          # being called and Deas' logging doesn't finish. They should always
          # be false.
          set :raise_errors,     false
          set :show_exceptions,  false

          # turn off logging, dump_errors b/c Deas handles its own logging logic
          set :logging,          false
          set :dump_errors,      false

          server_config.middlewares.each{ |use_args| use *use_args }

          # routes
          server_config.routes.each do |route|
            send(route.method, route.path) do
              begin
                route.run(
                  server_data,
                  RequestData.new({
                    :request    => request,
                    :response   => response,
                    :params     => params,
                    :route_path => route.path
                  })
                )
              rescue *STANDARD_ERROR_CLASSES => err
                request.env['deas.error'] = err
                response.status = DEFAULT_ERROR_RESPONSE_STATUS
                ErrorHandler.run(request.env['deas.error'], {
                  :server_data   => server_data,
                  :request       => request,
                  :response      => response,
                  :handler_class => request.env['deas.handler_class'],
                  :handler       => request.env['deas.handler'],
                  :params        => request.env['deas.params'],
                  :splat         => request.env['deas.splat'],
                  :route_path    => request.env['deas.route_path']
                })
              end
            end
          end

          not_found do
            # `self` is the sinatra call in this context
            if env['sinatra.error']
              env['deas.error'] = if env['sinatra.error'].instance_of?(::Sinatra::NotFound)
                Deas::NotFound.new(env['PATH_INFO']).tap do |e|
                  e.set_backtrace(env['sinatra.error'].backtrace)
                end
              else
                env['sinatra.error']
              end
              ErrorHandler.run(env['deas.error'], {
                :server_data   => server_data,
                :request       => request,
                :response      => response,
                :handler_class => request.env['deas.handler_class'],
                :handler       => request.env['deas.handler'],
                :params        => request.env['deas.params'],
                :splat         => request.env['deas.splat'],
                :route_path    => request.env['deas.route_path']
              })
            end
          end
        end
      end

    end

    module ClassMethods

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

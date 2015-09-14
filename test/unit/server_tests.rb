require 'assert'
require 'deas/server'

require 'logger'
require 'deas/exceptions'
require 'deas/logger'
require 'deas/router'
require 'deas/template_source'
require 'test/support/view_handlers'

module Deas::Server

  class UnitTests < Assert::Context
    desc "Deas::Server"
    setup do
      @server_class = Class.new{ include Deas::Server }
    end
    subject{ @server_class }

    should have_imeths :new, :configuration

    # DSL for sinatra-based settings
    should have_imeths :env, :root, :public_root, :views_root
    should have_imeths :dump_errors, :method_override, :sessions, :show_exceptions
    should have_imeths :static_files, :reload_templates

    # DSL for server handling settings
    should have_imeths :init, :error, :template_helpers, :template_helper?
    should have_imeths :use, :set, :verbose_logging, :logger, :default_encoding
    should have_imeths :template_source

    # DSL for server routing settings
    should have_imeths :router, :view_handler_ns, :base_url
    should have_imeths :url, :url_for
    should have_imeths :default_request_type_name, :add_request_type
    should have_imeths :request_type_name
    should have_imeths :get, :post, :put, :patch, :delete
    should have_imeths :route, :redirect

    should "allow setting it's configuration options" do
      config = subject.configuration

      subject.env 'staging'
      assert_equal 'staging', config.env

      subject.root '/path/to/root'
      assert_equal '/path/to/root', config.root.to_s

      subject.public_root '/path/to/public'
      assert_equal '/path/to/public', config.public_root.to_s

      subject.views_root '/path/to/views'
      assert_equal '/path/to/views', config.views_root.to_s

      subject.dump_errors true
      assert_equal true, config.dump_errors

      subject.method_override false
      assert_equal false, config.method_override

      subject.sessions false
      assert_equal false, config.sessions

      subject.show_exceptions true
      assert_equal true, config.show_exceptions

      subject.static_files false
      assert_equal false, config.static_files

      subject.reload_templates true
      assert_equal true, config.reload_templates

      assert_equal 0, config.init_procs.size
      init_proc = proc{ }
      subject.init(&init_proc)
      assert_equal 1, config.init_procs.size
      assert_equal init_proc, config.init_procs.first

      assert_equal 0, config.error_procs.size
      error_proc = proc{ }
      subject.error(&error_proc)
      assert_equal 1, config.error_procs.size
      assert_equal error_proc, config.error_procs.first

      subject.use 'MyMiddleware'
      assert_equal [ ['MyMiddleware'] ], config.middlewares

      subject.set :testing_set_meth, 'it works!'
      assert_equal({ :testing_set_meth => 'it works!'}, config.settings)

      stdout_logger = Logger.new(STDOUT)
      subject.logger stdout_logger
      assert_equal stdout_logger, config.logger

      a_source = Deas::TemplateSource.new(Factory.path)
      subject.template_source a_source
      assert_equal a_source, config.template_source

      subject.default_encoding 'latin1'
      assert_equal 'latin1', config.default_encoding
    end

    should "add and query helper modules" do
      subject.template_helpers(helper_module = Module.new)
      assert subject.template_helper?(helper_module)
    end

    should "have a router by default and allow overriding it" do
      assert_kind_of Deas::Router, subject.router
      assert_equal subject.router.view_handler_ns, subject.view_handler_ns
      assert_equal subject.router.base_url, subject.base_url

      new_router = Deas::Router.new
      subject.router new_router
      assert_same new_router, subject.router
    end

  end

  class ConfigurationTests < UnitTests
    desc "Configuration"
    setup do
      @configuration = Configuration.new
      @configuration.root = TEST_SUPPORT_ROOT
    end
    subject{ @configuration }

    # sinatra-based options

    should have_imeths :env, :root, :public_root, :views_root
    should have_imeths :dump_errors, :method_override, :sessions, :show_exceptions
    should have_imeths :static_files, :reload_templates, :default_encoding

    # server handling options

    should have_imeths :verbose_logging, :logger, :template_source

    should have_accessors :settings, :init_procs, :error_procs, :template_helpers
    should have_accessors :middlewares, :router
    should have_imeths :valid?, :validate!, :urls, :routes
    should have_imeths :to_hash

    should "default the env to 'development'" do
      assert_equal 'development', subject.env
    end

    should "default the public and views folders based off the root" do
      assert_equal subject.root.join('public'), subject.public_root
      assert_equal subject.root.join('views'), subject.views_root
    end

    should "default the Sinatra flags" do
      assert_equal false, subject.dump_errors
      assert_equal true,  subject.method_override
      assert_equal false, subject.sessions
      assert_equal false, subject.show_exceptions
      assert_equal true,  subject.static_files
      assert_equal false, subject.reload_templates
    end

    should "default the handling options" do
      assert_equal true, subject.verbose_logging
      assert_instance_of Deas::NullLogger, subject.logger
      assert_instance_of Deas::NullTemplateSource, subject.template_source
    end

    should "default its stored configuration" do
      assert_empty subject.settings
      assert_empty subject.error_procs
      assert_empty subject.init_procs
      assert_empty subject.template_helpers
      assert_empty subject.middlewares
      assert_empty subject.routes
      assert_empty subject.urls
      assert_kind_of Deas::Router, subject.router
    end

    should "not be valid until validate! has been run" do
      assert_not subject.valid?

      subject.validate!
      assert subject.valid?
    end

    should "complain if validating and `root` isn't set" do
      config = Configuration.new
      assert_raises(Deas::ServerRootError){ config.validate! }
      assert_nothing_raised{ config.root '/path/to/root'; config.validate! }
    end

    should "use `utf-8` as the default encoding by default" do
      assert_equal 'utf-8', subject.default_encoding
    end

    should "include its error procs and router in its `to_hash`" do
      config_hash = subject.to_hash

      assert_equal subject.error_procs, config_hash[:error_procs]
      assert_equal subject.router,      config_hash[:router]
    end

  end

  class ValidationTests < ConfigurationTests
    desc "when successfully validated"
    setup do
      @initialized = false
      @other_initialized = false
      @router = Deas::Router.new
      @route = @router.get('/something', 'EmptyViewHandler')
      @proxy = @route.handler_proxies[@router.default_request_type_name]

      @configuration = Configuration.new.tap do |c|
        c.env              = 'staging'
        c.root             = 'path/to/somewhere'
        c.dump_errors      = true
        c.method_override  = false
        c.sessions         = false
        c.show_exceptions  = true
        c.static           = true
        c.reload_templates = true
        c.middlewares      = [ ['MyMiddleware'] ]
        c.router           = @router
      end
      @configuration.init_procs << proc{ @initialized = true }
      @configuration.init_procs << proc{ @other_initialized = true }
    end

    should "call init procs" do
      assert_equal false, @initialized
      assert_equal false, @other_initialized

      subject.validate!

      assert_equal true, @initialized
      assert_equal true, @other_initialized
    end

    should "call validate! on all routes" do
      assert_nil @proxy.handler_class

      subject.validate!
      assert_equal EmptyViewHandler, @proxy.handler_class
    end

    should "add the Logging and ShowExceptions middleware to the end" do
      num_middlewares = subject.middlewares.size
      assert subject.verbose_logging
      assert_not_equal [Deas::ShowExceptions], subject.middlewares[-2]
      assert_not_equal [Deas::VerboseLogging], subject.middlewares[-1]

      subject.validate!

      assert_equal (num_middlewares+2), subject.middlewares.size
      assert_equal [Deas::ShowExceptions], subject.middlewares[-2]
      assert_equal [Deas::VerboseLogging], subject.middlewares[-1]
    end

  end

end

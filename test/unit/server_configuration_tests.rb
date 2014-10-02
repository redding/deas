require 'assert'
require 'deas/server'

require 'test/support/view_handlers'
require 'deas/exceptions'
require 'deas/template'
require 'deas/router'

class Deas::Server::Configuration

  class UnitTests < Assert::Context
    desc "Deas::Server::Configuration"
    setup do
      @configuration = Deas::Server::Configuration.new
      @configuration.root = TEST_SUPPORT_ROOT
    end
    subject{ @configuration }

    # sinatra-based options

    should have_imeths :env, :root, :public_root, :views_root
    should have_imeths :dump_errors, :method_override, :sessions, :show_exceptions
    should have_imeths :static_files, :reload_templates, :default_charset

    # server handling options

    should have_imeths :verbose_logging, :logger

    should have_accessors :settings, :error_procs, :init_procs, :template_helpers
    should have_accessors :middlewares, :router
    should have_imeths :valid?, :validate!, :urls, :routes, :template_scope

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
      assert_instance_of Deas::NullLogger, subject.logger
      assert_equal true, subject.verbose_logging
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

    should "build a template scope including its template helpers" do
      config = Deas::Server::Configuration.new
      config.template_helpers << (helper_module = Module.new)

      assert_includes Deas::Template::Scope, config.template_scope.ancestors
      assert_includes helper_module, config.template_scope.included_modules
    end

    should "not be valid until validate! has been run" do
      assert_not subject.valid?

      subject.validate!
      assert subject.valid?
    end

    should "complain if validating and `root` isn't set" do
      config = Deas::Server::Configuration.new
      assert_raises(Deas::ServerRootError){ config.validate! }
      assert_nothing_raised{ config.root '/path/to/root'; config.validate! }
    end

    should "use `utf-8` as the default_charset by default" do
      assert_equal 'utf-8', subject.default_charset
    end

  end

  class ValidationTests < UnitTests
    desc "when successfully validated"
    setup do
      @initialized = false
      @other_initialized = false
      proxy = Deas::RouteProxy.new('EmptyViewHandler')
      @route = Deas::Route.new(:get, '/something', proxy)
      @router = Deas::Router.new
      @router.routes = [ @route ]

      @configuration = Deas::Server::Configuration.new.tap do |c|
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

    should "call constantize! on all routes" do
      assert_nil @route.handler_class

      subject.validate!

      assert_equal EmptyViewHandler, @route.handler_class
    end

    should "default the :erb :outvar setting in the SinatraApp it creates" do
      assert_nil subject.settings[:erb]

      subject.validate!

      assert_kind_of ::Hash, subject.settings[:erb]
      assert_equal '@_out_buf', subject.settings[:erb][:outvar]
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

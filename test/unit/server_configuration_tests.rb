require 'assert'
require 'set'
require 'test/support/view_handlers'
require 'deas/exceptions'
require 'deas/template'
require 'deas/server'

class Deas::Server::Configuration

  class BaseTests < Assert::Context
    desc "Deas::Server::Configuration"
    setup do
      @configuration = Deas::Server::Configuration.new
      @configuration.root = TEST_SUPPORT_ROOT
    end
    subject{ @configuration }

    # sinatra related options
    should have_imeths :env, :root, :public_folder, :views_folder
    should have_imeths :dump_errors, :method_override, :sessions, :show_exceptions
    should have_imeths :static_files, :reload_templates

    # server handling options
    should have_imeths :error_procs, :init_procs, :logger, :middlewares, :settings
    should have_imeths :verbose_logging, :routes, :view_handler_ns, :default_charset

    should have_reader :template_helpers
    should have_imeths :valid?, :validate!

    should "default the env to 'development'" do
      assert_equal 'development', subject.env
    end

    should "default the public and views folders based off the root" do
      assert_equal subject.root.join('public'), subject.public_folder
      assert_equal subject.root.join('views'), subject.views_folder
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
      assert_empty subject.error_procs
      assert_empty subject.init_procs
      assert_instance_of Deas::NullLogger, subject.logger
      assert_empty subject.middlewares
      assert_empty subject.settings
      assert_equal true, subject.verbose_logging
      assert_empty subject.routes
      assert_nil   subject.view_handler_ns
      assert_empty subject.template_helpers
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

  class ValidationTests < BaseTests
    desc "when successfully validated"
    setup do
      @initialized = false
      @other_initialized = false
      @route = Deas::Route.new(:get, '/something', 'TestViewHandler')

      @configuration = Deas::Server::Configuration.new.tap do |c|
        c.env              = 'staging'
        c.root             = 'path/to/somewhere'
        c.dump_errors      = true
        c.method_override  = false
        c.sessions         = false
        c.show_exceptions  = true
        c.static           = true
        c.reload_templates = true
        c.routes           = [ @route ]
        c.middlewares      = [ ['MyMiddleware'] ]
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

      assert_equal TestViewHandler, @route.handler_class
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

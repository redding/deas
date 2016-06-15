require 'assert'
require 'deas/server'

require 'logger'
require 'much-plugin'
require 'deas/exceptions'
require 'deas/logger'
require 'deas/router'
require 'deas/template_source'
require 'test/support/empty_view_handler'

module Deas::Server

  class UnitTests < Assert::Context
    desc "Deas::Server"
    setup do
      @server_class = Class.new{ include Deas::Server }
    end
    subject{ @server_class }

    should have_imeths :new, :config

    should have_imeths :env, :root, :views_path, :views_root
    should have_imeths :public_path, :public_root, :default_encoding
    should have_imeths :set, :settings, :template_helpers, :template_helper?
    should have_imeths :use, :middlewares, :init, :init_procs, :error, :error_procs
    should have_imeths :template_source, :logger, :router, :url_for

    should have_imeths :dump_errors, :method_override, :reload_templates
    should have_imeths :sessions, :show_exceptions, :static_files
    should have_imeths :verbose_logging

    should "use much-plugin" do
      assert_includes MuchPlugin, Deas::Server
    end

    should "allow setting its config values" do
      config = subject.config

      exp = Factory.string
      subject.env exp
      assert_equal exp, config.env

      exp = Factory.path
      subject.root exp
      assert_equal exp, config.root

      exp = Factory.path
      subject.views_path exp
      assert_equal exp, config.views_path

      exp = Factory.path
      subject.public_path exp
      assert_equal exp, config.public_path

      exp = Factory.string
      subject.default_encoding exp
      assert_equal exp, config.default_encoding

      exp = { Factory.string.to_sym => Factory.string }
      subject.set exp.keys.first, exp.values.first
      assert_equal exp, config.settings

      exp = ['MyMiddleware', Factory.string]
      subject.use *exp
      assert_equal [exp], config.middlewares

      exp = proc{ }
      assert_equal 0, config.init_procs.size
      subject.init(&exp)
      assert_equal 1, config.init_procs.size
      assert_equal exp, config.init_procs.first

      exp = proc{ }
      assert_equal 0, config.error_procs.size
      subject.error(&exp)
      assert_equal 1, config.error_procs.size
      assert_equal exp, config.error_procs.first

      exp = Deas::TemplateSource.new(Factory.path)
      subject.template_source exp
      assert_equal exp, config.template_source

      exp = Logger.new(STDOUT)
      subject.logger exp
      assert_equal exp, config.logger

      exp = Factory.boolean
      subject.dump_errors exp
      assert_equal exp, config.dump_errors

      exp = Factory.boolean
      subject.method_override exp
      assert_equal exp, config.method_override

      exp = Factory.boolean
      subject.reload_templates exp
      assert_equal exp, config.reload_templates

      exp = Factory.boolean
      subject.sessions exp
      assert_equal exp, config.sessions

      exp = Factory.boolean
      subject.show_exceptions exp
      assert_equal exp, config.show_exceptions

      exp = Factory.boolean
      subject.static_files exp
      assert_equal exp, config.static_files

      exp = Factory.boolean
      subject.verbose_logging exp
      assert_equal exp, config.verbose_logging
    end

    should "demeter its config values that aren't directly set" do
      assert_equal subject.config.views_root,  subject.views_root
      assert_equal subject.config.public_root, subject.public_root
      assert_equal subject.config.settings,    subject.settings
      assert_equal subject.config.middlewares, subject.middlewares
      assert_equal subject.config.init_procs,  subject.init_procs
      assert_equal subject.config.error_procs, subject.error_procs
    end

    should "add and query helper modules" do
      subject.template_helpers(helper_module = Module.new)
      assert_true subject.template_helper?(helper_module)
    end

    should "have a router by default and allow overriding it" do
      assert_kind_of Deas::Router, subject.router

      new_router = Deas::Router.new
      subject.router new_router
      assert_same new_router, subject.config.router
      assert_same new_router, subject.router
    end

    should "allow configuring the router by passing a block to `router`" do
      block_scope = nil
      subject.router{ block_scope = self }
      assert_equal subject.router, block_scope
    end

    should "call the router's `url_for` method" do
      url_for_called_args = nil
      url_for_called_proc = nil
      Assert.stub(subject.router, :url_for) do |*args, &block|
        url_for_called_args = args
        url_for_called_proc = block
      end

      exp_args = [Factory.string]
      exp_proc = proc{ }
      subject.url_for(*exp_args, &exp_proc)
      assert_equal exp_args, url_for_called_args
      assert_equal exp_proc, url_for_called_proc
    end

  end

  class ConfigTests < UnitTests
    desc "Config"
    setup do
      @config_class = Config
      @config = @config_class.new
    end
    subject{ @config }

    should have_accessors :env, :root, :views_path, :public_path, :default_encoding
    should have_accessors :settings, :template_helpers, :middlewares
    should have_accessors :init_procs, :error_procs, :template_source, :logger, :router

    should have_accessors :dump_errors, :method_override, :reload_templates
    should have_accessors :sessions, :show_exceptions, :static_files
    should have_accessors :verbose_logging

    should have_imeths :views_root, :public_root, :urls, :routes
    should have_imeths :valid?, :validate!

    should "know its default attr values" do
      assert_equal 'development', @config_class::DEFAULT_ENV
      assert_equal 'views',       @config_class::DEFAULT_VIEWS_PATH
      assert_equal 'public',      @config_class::DEFAULT_PUBLIC_PATH
      assert_equal 'utf-8',       @config_class::DEFAULT_ENCODING
    end

    should "default its attrs" do
      exp = @config_class::DEFAULT_ENV
      assert_equal exp, subject.env

      exp = ENV['PWD']
      assert_equal exp, subject.root

      exp = @config_class::DEFAULT_VIEWS_PATH
      assert_equal exp, subject.views_path

      exp = @config_class::DEFAULT_PUBLIC_PATH
      assert_equal exp, subject.public_path

      exp = @config_class::DEFAULT_ENCODING
      assert_equal exp, subject.default_encoding

      assert_equal Hash.new, subject.settings
      assert_equal [],       subject.template_helpers
      assert_equal [],       subject.middlewares
      assert_equal [],       subject.init_procs
      assert_equal [],       subject.error_procs

      assert_instance_of Deas::NullTemplateSource, subject.template_source
      assert_equal subject.root, subject.template_source.path

      assert_instance_of Deas::NullLogger, subject.logger
      assert_instance_of Deas::Router,     subject.router

      assert_equal false, subject.dump_errors
      assert_equal true,  subject.method_override
      assert_equal false, subject.reload_templates
      assert_equal false, subject.sessions
      assert_equal false, subject.show_exceptions
      assert_equal true,  subject.static_files
      assert_equal true,  subject.verbose_logging
    end

    should "know its views root and public root" do
      exp = File.expand_path(subject.views_path.to_s, subject.root.to_s)
      assert_equal exp, subject.views_root

      exp = File.expand_path(subject.public_path.to_s, subject.root.to_s)
      assert_equal exp, subject.public_root
    end

    should "demeter its router" do
      assert_equal subject.router.urls,   subject.urls
      assert_equal subject.router.routes, subject.routes
    end

    should "not be valid until validate! has been run" do
      assert_false subject.valid?

      subject.validate!
      assert_true subject.valid?
    end

    should "complain if validating and its root value is nil" do
      config = Config.new
      config.root = nil
      assert_raises(Deas::ServerRootError){ config.validate! }
    end

  end

  class ValidationTests < ConfigTests
    desc "when successfully validated"
    setup do
      @router = Deas::Router.new
      @router_validate_called = false
      Assert.stub(@router, :validate!){ @router_validate_called = true }

      @config = Config.new.tap do |c|
        c.root             = Factory.path
        c.show_exceptions  = true
        c.verbose_logging  = true
        c.middlewares      = Factory.integer(3).times.map{ [Factory.string] }
        c.router           = @router
      end

      @initialized = false
      @config.init_procs << proc{ @initialized = true }

      @other_initialized = false
      @config.init_procs << proc{ @other_initialized = true }
    end

    should "call its init procs" do
      assert_equal false, @initialized
      assert_equal false, @other_initialized

      subject.validate!

      assert_equal true, @initialized
      assert_equal true, @other_initialized
    end

    should "call validate! on the router" do
      assert_false @router_validate_called

      subject.validate!
      assert_true @router_validate_called
    end

    should "add the Logging and ShowExceptions middleware to the end" do
      assert_true subject.show_exceptions
      assert_true subject.verbose_logging

      num_middlewares = subject.middlewares.size
      assert_not_equal [Deas::ShowExceptions], subject.middlewares[-2]
      assert_not_equal [Deas::VerboseLogging], subject.middlewares[-1]

      subject.validate!

      assert_equal (num_middlewares+2), subject.middlewares.size
      assert_equal [Deas::ShowExceptions], subject.middlewares[-2]
      assert_equal [Deas::VerboseLogging], subject.middlewares[-1]
    end

    should "only be able to be validated once" do
      called = 0
      subject.init_procs << proc{ called += 1 }
      subject.validate!
      assert_equal 1, called
      subject.validate!
      assert_equal 1, called
    end

  end

end

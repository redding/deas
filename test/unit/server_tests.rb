require 'assert'
require 'deas/server'

require 'logger'
require 'deas/router'
require 'deas/template_source'

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

end

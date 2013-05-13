require 'assert'
require 'deas/route'
require 'deas/server'
require 'logger'

module Deas::Server

  class BaseTests < Assert::Context
    desc "Deas::Server"
    setup do
      @server_class = Class.new{ include Deas::Server }
    end
    subject{ @server_class }

    should have_imeths :new, :configuration

    # DSL for sinatra settings
    should have_imeths :env, :root, :public_folder, :views_folder
    should have_imeths :dump_errors, :method_override, :sessions, :show_exceptions
    should have_imeths :static_files, :reload_templates

    # DSL for server handling
    should have_imeths :init, :logger, :use, :view_handler_ns, :use
    should have_imeths :get, :post, :put, :patch, :delete, :route

    should "allow setting it's configuration options" do
      config = subject.configuration

      subject.env 'staging'
      assert_equal 'staging', config.env

      subject.root '/path/to/root'
      assert_equal '/path/to/root', config.root.to_s

      subject.public_folder '/path/to/public'
      assert_equal '/path/to/public', config.public_folder.to_s

      subject.views_folder '/path/to/views'
      assert_equal '/path/to/views', config.views_folder.to_s

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

      subject.use 'MyMiddleware'
      assert_equal [ ['MyMiddleware'] ], config.middlewares

      stdout_logger = Logger.new(STDOUT)
      subject.logger stdout_logger
      assert_equal stdout_logger, config.logger

      assert_equal 0, config.init_procs.size
      init_proc = proc{ }
      subject.init(&init_proc)
      assert_equal 1, config.init_procs.size
      assert_equal init_proc, config.init_procs.first
    end

    should "add a GET route using #get" do
      subject.get('/assets', 'ListAssets')

      route = subject.configuration.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :get,         route.method
      assert_equal '/assets',    route.path
      assert_equal 'ListAssets', route.handler_class_name
    end

    should "add a POST route using #post" do
      subject.post('/assets', 'CreateAsset')

      route = subject.configuration.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :post,         route.method
      assert_equal '/assets',     route.path
      assert_equal 'CreateAsset', route.handler_class_name
    end

    should "add a PUT route using #put" do
      subject.put('/assets/:id', 'UpdateAsset')

      route = subject.configuration.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :put,          route.method
      assert_equal '/assets/:id', route.path
      assert_equal 'UpdateAsset', route.handler_class_name
    end

    should "add a PATCH route using #patch" do
      subject.patch('/assets/:id', 'UpdateAsset')

      route = subject.configuration.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :patch,        route.method
      assert_equal '/assets/:id', route.path
      assert_equal 'UpdateAsset', route.handler_class_name
    end

    should "add a DELETE route using #delete" do
      subject.delete('/assets/:id', 'DeleteAsset')

      route = subject.configuration.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :delete,       route.method
      assert_equal '/assets/:id', route.path
      assert_equal 'DeleteAsset', route.handler_class_name
    end

    should "allow defining any kind of route using #route" do
      subject.route(:options, '/get_info', 'GetInfo')

      route = subject.configuration.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :options,    route.method
      assert_equal '/get_info', route.path
      assert_equal 'GetInfo',   route.handler_class_name
    end

    should "set a namespace with #view_handler_ns and " \
           "use it when defining routes" do
      subject.view_handler_ns 'MyStuff'
      assert_equal 'MyStuff', subject.configuration.view_handler_ns

      # should use the ns
      subject.route(:get, '/ns_test',     'NsTest')
      route = subject.configuration.routes.last
      assert_equal 'MyStuff::NsTest', route.handler_class_name

      # should ignore the ns when the leading colons are present
      subject.route(:post, '/no_ns_test', '::NoNsTest')
      route = subject.configuration.routes.last
      assert_equal '::NoNsTest', route.handler_class_name
    end

  end

  class ConfigurationTests < BaseTests
    desc "Configuration"
    setup do
      @configuration = Deas::Server::Configuration.new
    end
    subject{ @configuration }

    # sinatra related options
    should have_imeths :env, :root, :public_folder, :views_folder
    should have_imeths :dump_errors, :method_override, :sessions, :show_exceptions
    should have_imeths :static_files, :reload_templates

    # server handling options
    should have_imeths :init_procs, :logger, :verbose_logging, :middlewares
    should have_imeths :routes, :view_handler_ns

    should "default the env to 'development'" do
      assert_equal 'development', subject.env
    end

    should "default the public and views folders based off the root" do
      subject.root = TEST_SUPPORT_ROOT

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

    should "default the logger to a NullLogger" do
      assert_instance_of Deas::NullLogger, subject.logger
    end

    should "default routes to an empty array" do
      assert_equal [], subject.routes
    end

    should "default middlewares to an empty array" do
      assert_equal [], subject.middlewares
    end

  end

end

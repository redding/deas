require 'assert'
require 'deas/server'

class Deas::Server

  class BaseTests < Assert::Context
    desc "Deas::Server"
    setup do
      @old_configuration = Deas::Server.configuration.dup
      new_configuration = Deas::Server::Configuration.new
      Deas::Server.instance.tap do |s|
        s.instance_variable_set("@configuration", new_configuration)
      end
    end
    teardown do
      Deas::Server.instance.tap do |s|
        s.instance_variable_set("@configuration", @old_configuration)
      end
    end
    subject{ Deas::Server }

    should have_instance_methods :configuration, :init, :view_handler_ns,
      :get, :post, :put, :patch, :delete, :route

    should "be a singleton" do
      assert_includes Singleton, subject.included_modules
    end

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

      subject.static_files false
      assert_equal false, config.static_files

      stdout_logger = Logger.new(STDOUT)
      subject.logger stdout_logger
      assert_equal stdout_logger, config.logger

      init_proc = proc{ }
      subject.init(&init_proc)
      assert_equal init_proc, config.init_proc
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

    should have_instance_methods :env, :root, :app_file, :public_folder,
      :views_folder, :dump_errors, :method_override, :sessions, :static_files,
      :init_proc, :logger, :routes, :view_handler_ns

    should "default the env to 'development'" do
      assert_equal 'development', subject.env
    end

    should "default the root to the routes file's folder" do
      expected_root = File.expand_path('..', Deas.config.routes_file)
      assert_equal expected_root, subject.root.to_s
    end

    should "default the app file to the routes file" do
      assert_equal Deas.config.routes_file.to_s, subject.app_file.to_s
    end

    should "default the public folder based on the root" do
      expected_root = File.expand_path('..', Deas.config.routes_file)
      expected_public_folder = File.join(expected_root, 'public')
      assert_equal expected_public_folder, subject.public_folder.to_s
    end

    should "default the views folder based on the root" do
      expected_root = File.expand_path('..', Deas.config.routes_file)
      expected_views_folder = File.join(expected_root, 'views')
      assert_equal expected_views_folder, subject.views_folder.to_s
    end

    should "default the Sinatra flags" do
      assert_equal false, subject.dump_errors
      assert_equal true,  subject.method_override
      assert_equal true,  subject.sessions
      assert_equal true,  subject.static_files
    end

    should "default the logger to a NullLogger" do
      assert_instance_of Deas::NullLogger, subject.logger
    end

    should "default routes to an empty array" do
      assert_equal [], subject.routes
    end

  end

end

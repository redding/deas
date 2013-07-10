require 'assert'
require 'set'
require 'logger'
require 'deas/route'
require 'deas/server'

module Deas::Server

  class BaseTests < Assert::Context
    desc "Deas::Server"
    setup do
      @server_class = Class.new{ include Deas::Server }
    end
    subject{ @server_class }

    should have_imeths :new, :configuration

    # DSL for sinatra-based settings
    should have_imeths :env, :root, :public_folder, :views_folder
    should have_imeths :dump_errors, :method_override, :sessions, :show_exceptions
    should have_imeths :static_files, :reload_templates, :default_charset

    # DSL for server handling settings
    should have_imeths :init, :error, :template_helpers, :template_helper?
    should have_imeths :use, :set, :view_handler_ns, :verbose_logging, :logger
    should have_imeths :get, :post, :put, :patch, :delete
    should have_imeths :redirect, :route, :url

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

      subject.default_charset 'latin1'
      assert_equal 'latin1', config.default_charset
    end

    should "add and query helper modules" do
      subject.template_helpers(helper_module = Module.new)
      assert subject.template_helper?(helper_module)
    end

    should "set a namespace and use it when defining routes" do
      subject.view_handler_ns 'MyStuff'
      assert_equal 'MyStuff', subject.configuration.view_handler_ns

      # should use the ns
      route = subject.route(:get, '/ns_test', 'NsTest')
      assert_equal 'MyStuff::NsTest', route.handler_proxy.handler_class_name

      # should ignore the ns when the leading colons are present
      route = subject.route(:post, '/no_ns_test', '::NoNsTest')
      assert_equal '::NoNsTest', route.handler_proxy.handler_class_name
    end

    should "add a GET route using #get" do
      subject.get('/things', 'ListThings')

      route = subject.configuration.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :get,         route.method
      assert_equal '/things',    route.path
      assert_equal 'ListThings', route.handler_proxy.handler_class_name
    end

    should "add a POST route using #post" do
      subject.post('/things', 'CreateThing')

      route = subject.configuration.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :post,         route.method
      assert_equal '/things',     route.path
      assert_equal 'CreateThing', route.handler_proxy.handler_class_name
    end

    should "add a PUT route using #put" do
      subject.put('/things/:id', 'UpdateThing')

      route = subject.configuration.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :put,          route.method
      assert_equal '/things/:id', route.path
      assert_equal 'UpdateThing', route.handler_proxy.handler_class_name
    end

    should "add a PATCH route using #patch" do
      subject.patch('/things/:id', 'UpdateThing')

      route = subject.configuration.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :patch,        route.method
      assert_equal '/things/:id', route.path
      assert_equal 'UpdateThing', route.handler_proxy.handler_class_name
    end

    should "add a DELETE route using #delete" do
      subject.delete('/things/:id', 'DeleteThing')

      route = subject.configuration.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :delete,       route.method
      assert_equal '/things/:id', route.path
      assert_equal 'DeleteThing', route.handler_proxy.handler_class_name
    end

    should "add a redirect route using #redirect" do
      subject.redirect(:get, '/invalid', '/assets')

      route = subject.configuration.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :get,       route.method
      assert_equal '/invalid', route.path
      assert_equal 'Deas::RedirectHandler', route.handler_proxy.handler_class_name

      route.validate!
      assert_not_nil route.handler_class
    end

    should "allow defining any kind of route using #route" do
      subject.route(:options, '/get_info', 'GetInfo')

      route = subject.configuration.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :options,    route.method
      assert_equal '/get_info', route.path
      assert_equal 'GetInfo',   route.handler_proxy.handler_class_name
    end

    should "not define urls for routes created with no url name" do
      assert_empty subject.configuration.urls

      @server_class.route(:get, '/info', 'GetInfo')
      assert_empty subject.configuration.urls

      @server_class.route(:get, '/info', 'GetInfo', nil)
      assert_empty subject.configuration.urls

      @server_class.route(:get, '/info', 'GetInfo', '')
      assert_empty subject.configuration.urls

      @server_class.route(:get, '/info', 'GetInfo', 'get_info')
      assert_not_empty subject.configuration.urls
    end

  end

  class NamedUrlTests < BaseTests
    desc "when defining a route with a url name"
    setup do
      @server_class.route(:get, '/info/:for', 'GetInfo', 'get_info')
    end

    should "define a url for the route on the server" do
      url = subject.configuration.urls[:get_info]

      assert_not_nil url
      assert_kind_of Deas::Url, url
      assert_equal :get_info, url.name
      assert_equal '/info/:for', url.path
    end

    should "complain if given a non-string path" do
      assert_raises ArgumentError do
        subject.route(:get, /^\/info/, 'GetInfo', 'get_info')
      end
    end

    should "build a path for a url given params" do
      exp_path = "/info/now"

      assert_equal exp_path, subject.url(:get_info, :for => 'now')
      assert_equal exp_path, subject.url(:get_info, 'now')
    end

    should "complain if building a named url that hasn't been defined" do
      assert_raises ArgumentError do
        subject.url(:get_all_info, 'now')
      end
    end

    should "complain if redirecting to a named url that hasn't been defined" do
      assert_raises ArgumentError do
        subject.redirect(:get, '/somewhere', :not_defined_url)
      end
    end

  end

end

require 'assert'
require 'deas/router'

class Deas::Router

  class UnitTests < Assert::Context
    desc "Deas::Router"
    setup do
      @router = Deas::Router.new
    end
    subject{ @router }

    should have_accessors :urls, :routes
    should have_imeths :view_handler_ns, :base_url
    should have_imeths :url, :url_for
    should have_imeths :get, :post, :put, :patch, :delete
    should have_imeths :route, :redirect

    should "have no view_handler_ns, base_url, urls, or routes by default" do
      assert_nil subject.view_handler_ns
      assert_nil subject.base_url
      assert_empty subject.urls
      assert_empty subject.routes
    end

    should "add a GET route using #get" do
      subject.get('/things', 'ListThings')

      route = subject.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :get,         route.method
      assert_equal '/things',    route.path
      assert_equal 'ListThings', route.handler_proxy.handler_class_name
    end

    should "add a POST route using #post" do
      subject.post('/things', 'CreateThing')

      route = subject.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :post,         route.method
      assert_equal '/things',     route.path
      assert_equal 'CreateThing', route.handler_proxy.handler_class_name
    end

    should "add a PUT route using #put" do
      subject.put('/things/:id', 'UpdateThing')

      route = subject.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :put,          route.method
      assert_equal '/things/:id', route.path
      assert_equal 'UpdateThing', route.handler_proxy.handler_class_name
    end

    should "add a PATCH route using #patch" do
      subject.patch('/things/:id', 'UpdateThing')

      route = subject.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :patch,        route.method
      assert_equal '/things/:id', route.path
      assert_equal 'UpdateThing', route.handler_proxy.handler_class_name
    end

    should "add a DELETE route using #delete" do
      subject.delete('/things/:id', 'DeleteThing')

      route = subject.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :delete,       route.method
      assert_equal '/things/:id', route.path
      assert_equal 'DeleteThing', route.handler_proxy.handler_class_name
    end

    should "allow defining any kind of route using #route" do
      subject.route(:options, '/get_info', 'GetInfo')

      route = subject.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :options,    route.method
      assert_equal '/get_info', route.path
      assert_equal 'GetInfo',   route.handler_proxy.handler_class_name
    end

    should "set a view handler namespace and use it when defining routes" do
      subject.view_handler_ns 'MyStuff'
      assert_equal 'MyStuff', subject.view_handler_ns

      # should use the ns
      route = subject.route(:get, '/ns_test', 'NsTest')
      assert_equal 'MyStuff::NsTest', route.handler_proxy.handler_class_name

      # should ignore the ns when the leading colons are present
      route = subject.route(:post, '/no_ns_test', '::NoNsTest')
      assert_equal '::NoNsTest', route.handler_proxy.handler_class_name
    end

    should "set a base url" do
      url = Factory.url
      subject.base_url url

      assert_equal url, subject.base_url
    end

    should "use the base url when adding routes" do
      url = Factory.url
      subject.base_url url
      route = subject.get('/some-path', Object)

      exp_path = "#{url}/some-path"
      assert_equal exp_path, route.path
    end

    should "add a redirect route using #redirect" do
      subject.redirect('/invalid', '/assets')

      route = subject.routes[0]
      assert_instance_of Deas::Route, route
      assert_equal :get,       route.method
      assert_equal '/invalid', route.path
      assert_equal 'Deas::RedirectHandler', route.handler_proxy.handler_class_name

      route.validate!
      assert_not_nil route.handler_class
    end

    should "instance eval any given block" do
      router = Deas::Router.new do
        get('/things', 'ListThings')
      end

      assert_equal 1, router.routes.size
      assert_instance_of Deas::Route, router.routes.first
    end

  end

  class NamedUrlTests < UnitTests
    desc "when using named urls"
    setup do
      @router.url('get_info', '/info/:for')
    end

    should "define a url given a name and a path" do
      url = subject.urls[:get_info]

      assert_not_nil url
      assert_kind_of Deas::Url, url
      assert_equal :get_info, url.name
      assert_equal '/info/:for', url.path
    end

    should "complain if defining a url with a non-string path" do
      assert_raises ArgumentError do
        subject.url(:get_info, /^\/info/)
      end
    end

    should "build a path for a url given params" do
      exp_path = "/info/now"
      assert_equal exp_path, subject.url_for(:get_info, :for => 'now')
      assert_equal exp_path, subject.url_for(:get_info, 'now')
    end

    should "'squash' duplicate forward-slashes when building urls" do
      exp_path = "/info/now"
      assert_equal exp_path, subject.url_for(:get_info, :for => '/now')
      assert_equal exp_path, subject.url_for(:get_info, '/now')
    end

    should "complain if building a named url that hasn't been defined" do
      assert_raises ArgumentError do
        subject.url_for(:get_all_info, 'now')
      end
    end

    should "complain if redirecting to a named url that hasn't been defined" do
      assert_raises ArgumentError do
        subject.redirect('/somewhere', :not_defined_url)
      end
    end

    should "redirect using a url name instead of a path" do
      subject.redirect(:get_info, '/somewhere')
      url   = subject.urls[:get_info]
      route = subject.routes.last

      assert_equal url.path, route.path
    end

    should "route using a url name instead of a path" do
      subject.route(:get, :get_info, 'GetInfo')
      url   = subject.urls[:get_info]
      route = subject.routes.last

      assert_equal url.path, route.path
    end

    should "use the base url when building named urls" do
      url = Factory.url
      subject.base_url url
      subject.url('base_get_info', '/info/:for')

      exp_path = "#{url}/info/now"
      assert_equal exp_path, subject.url_for(:base_get_info, :for => 'now')
    end

  end

end

require 'assert'
require 'deas/router'

require 'deas/exceptions'
require 'deas/route'
require 'test/support/view_handlers'

class Deas::Router

  class UnitTests < Assert::Context
    desc "Deas::Router"
    setup do
      @router_class = Deas::Router
    end
    subject{ @router_class }

    should "know its default request type name" do
      assert_equal 'default', subject::DEFAULT_REQUEST_TYPE_NAME
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @router = @router_class.new
    end
    subject{ @router }

    should have_readers :request_types, :urls, :routes
    should have_readers :escape_query_value_proc

    should have_imeths :view_handler_ns, :escape_query_value
    should have_imeths :base_url, :prepend_base_url
    should have_imeths :url, :url_for
    should have_imeths :default_request_type_name, :add_request_type
    should have_imeths :request_type_name
    should have_imeths :get, :post, :put, :patch, :delete
    should have_imeths :route, :redirect

    should "default its settings" do
      assert_nil subject.view_handler_ns
      assert_nil subject.base_url
      assert_empty subject.request_types
      assert_empty subject.urls
      assert_empty subject.routes

      exp = @router_class::DEFAULT_REQUEST_TYPE_NAME
      assert_equal exp, subject.default_request_type_name

      value = "#%&?"
      exp = Rack::Utils.escape(value)
      assert_equal exp, subject.escape_query_value_proc.call(value)
    end

    should "set a view handler namespace" do
      subject.view_handler_ns(exp = Factory.string)
      assert_equal exp, subject.view_handler_ns
    end

    should "allow configuring a custom escape query value proc" do
      escape_proc = proc{ Factory.string }
      subject.escape_query_value(&escape_proc)
      assert_equal escape_proc, subject.escape_query_value_proc

      assert_raises(ArgumentError){ subject.escape_query_value }
    end

    should "set a base url" do
      subject.base_url(exp = Factory.url)
      assert_equal exp, subject.base_url
    end

    should "prepend the base url to any url path" do
      url_path = Factory.path
      base_url = Factory.url

      assert_equal url_path, subject.prepend_base_url(url_path)

      subject.base_url base_url
      assert_equal "#{base_url}#{url_path}", subject.prepend_base_url(url_path)
    end

    should "prepend the base url when adding routes" do
      url = Factory.url
      subject.base_url url
      path = Factory.path
      route = subject.get(path, Object)

      exp_path = subject.prepend_base_url(path)
      assert_equal exp_path, route.path
    end

    should "prepend the base url when adding redirects" do
      url = Factory.url
      subject.base_url url
      path = Factory.path
      redirect = subject.redirect(path, Factory.path)

      exp_path = subject.prepend_base_url(path)
      assert_equal exp_path, redirect.path
    end

    should "set a default request type name" do
      subject.default_request_type_name(exp = Factory.string)
      assert_equal exp, subject.default_request_type_name
    end

    should "add request types" do
      assert_empty subject.request_types

      name, proc = Factory.string, Proc.new{}
      subject.add_request_type(name, &proc)
      assert_not_empty subject.request_types

      rt = subject.request_types.last
      assert_equal name, rt.name
      assert_equal proc, rt.proc
    end

    should "lookup request type names" do
      request = Factory.string
      name = Factory.string
      proc = Proc.new{ |r| r == request }
      subject.add_request_type(name, &proc)
      subject.add_request_type(Factory.string, &proc)

      exp = name
      assert_equal exp, subject.request_type_name(request)

      exp = subject.default_request_type_name
      assert_equal exp, subject.request_type_name(Factory.string)
    end

    should "add get, post, put, patch and delete routes" do
      Assert.stub(subject, :route){ |*args| RouteSpy.new(*args) }
      path = Factory.path
      args = [Factory.string]

      [:get, :post, :put, :patch, :delete].each do |meth|
        route = subject.send(meth, path, *args)
        assert_equal meth, route.method
        assert_equal path, route.path
        assert_equal args, route.args
      end
    end

    should "instance eval any given block" do
      ns = Factory.string
      router = Deas::Router.new do
        view_handler_ns ns
      end

      assert_equal ns, router.view_handler_ns
    end

  end

  class RouteTests < InitTests
    setup do
      @method = Factory.string
      @path1  = Factory.path
      @path2  = Factory.path
      @handler_class_name1 = Factory.string
      @handler_class_name2 = Factory.string
    end

    should "add a Route with the given method and path" do
      assert_empty subject.routes

      subject.route(@method, @path1)
      assert_not_empty subject.routes

      route = subject.routes.last
      assert_instance_of Deas::Route, route
      assert_equal @method, route.method
      assert_equal @path1,  route.path

      proxies = route.handler_proxies
      assert_kind_of HandlerProxies, proxies
      assert_empty proxies
      assert_equal subject.default_request_type_name, proxies.default_type
    end

    should "proxy any handler class given for the default request type" do
      subject.route(@method, @path1, @handler_class_name1)
      route = subject.routes.last
      proxy = route.handler_proxies[subject.default_request_type_name]
      assert_kind_of Deas::RouteProxy, proxy
      assert_equal @handler_class_name1, proxy.handler_class_name

      subject.route(@method, @path1, @handler_class_name1, {
        subject.default_request_type_name => @handler_class_name2
      })
      route = subject.routes.last
      proxy = route.handler_proxies[subject.default_request_type_name]
      assert_kind_of Deas::RouteProxy, proxy
      assert_not_nil proxy
      assert_equal @handler_class_name2, proxy.handler_class_name
    end

    should "proxy handler classes for their specified request types" do
      subject.route(@method, @path1, {
        '1' => @handler_class_name1,
        '2' => @handler_class_name2,
      })
      route = subject.routes.last

      proxy = route.handler_proxies['1']
      assert_kind_of Deas::RouteProxy, proxy
      assert_equal @handler_class_name1, proxy.handler_class_name

      proxy = route.handler_proxies['2']
      assert_kind_of Deas::RouteProxy, proxy
      assert_equal @handler_class_name2, proxy.handler_class_name
    end

    should "add redirect routes" do
      subject.redirect(@path1, @path2)

      route = subject.routes.last
      assert_instance_of Deas::Route, route
      assert_equal :get,   route.method
      assert_equal @path1, route.path

      proxy = route.handler_proxies[subject.default_request_type_name]
      assert_kind_of Deas::RedirectProxy, proxy
      assert_equal 'Deas::RedirectHandler', proxy.handler_class_name
    end

  end

  class NamedUrlTests < InitTests
    setup do
      @router.url('get_info', '/info/:for')
    end

    should "define a url given a name and a path" do
      url = subject.urls[:get_info]

      assert_not_nil url
      assert_kind_of Deas::Url, url
      assert_equal :get_info, url.name
      assert_equal '/info/:for', url.path
      assert_equal subject.escape_query_value_proc, url.escape_query_value_proc
    end

    should "define a url with a custom escape query value proc" do
      name = Factory.string
      escape_proc = proc{ Factory.string }
      @router.url(name, Factory.path, :escape_query_value => escape_proc)

      url = subject.urls[name.to_sym]
      assert_equal escape_proc, url.escape_query_value_proc
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

    should "prepend the base url when building named urls" do
      url = Factory.url
      subject.base_url url
      path = Factory.path
      subject.url('base_get_info', path)

      exp_path = subject.prepend_base_url(path)
      assert_equal exp_path, subject.url_for(:base_get_info)
    end

  end

  class HandlerProxiesTests < UnitTests
    desc "HandlerProxies"
    setup do
      @default_type = Factory.string
      @other_type   = Factory.string
      @proxies = {
        @default_type => Factory.string,
        @other_type   => Factory.string
      }
      @handler_proxies = HandlerProxies.new(@proxies, @default_type)
    end
    subject{ @handler_proxies }

    should have_reader :default_type
    should have_imeths :[], :each, :empty?

    should "know its default type" do
      assert_equal @default_type, subject.default_type
    end

    should "find the proxy for the given type" do
      assert_equal @proxies[@other_type], subject[@other_type]
    end

    should "find the default proxy if there is no proxy for the given type" do
      assert_equal @proxies[subject.default_type], subject[Factory.string]
    end

    should "complain if there is no proxy for the given type and no default proxy" do
      handler_proxies = HandlerProxies.new({}, @default_type)
      assert_raises(Deas::HandlerProxyNotFound) do
        handler_proxies[Factory.string]
      end
    end

    should "demeter its given proxies each method" do
      exp = ''
      @proxies.each{ |k, v| exp << v }
      act = ''
      subject.each{ |k, v| act << v }

      assert_equal exp, act
    end

    should "demeter its given proxies empty? method" do
      Assert.stub(@proxies, :empty?){ false }
      assert_false subject.empty?

      Assert.stub(@proxies, :empty?){ true }
      assert_true subject.empty?
    end

  end

  class RouteSpy < Struct.new(:method, :path, :args)
    def initialize(method, path, *args)
      super(method, path, args)
    end
  end
end

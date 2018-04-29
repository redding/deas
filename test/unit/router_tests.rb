require 'assert'
require 'deas/router'

require 'deas/exceptions'
require 'deas/route'
require 'deas/view_handler'
require 'test/support/empty_view_handler'

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

    should "know its trailing slashes constants" do
      assert_equal 'remove', subject::REMOVE_TRAILING_SLASHES
      assert_equal 'allow',  subject::ALLOW_TRAILING_SLASHES
      assert_equal '/',      subject::SLASH
    end

  end

  class InitTests < UnitTests
    include Deas::ViewHandler::TestHelpers

    desc "when init"
    setup do
      @base_url = a_base_url = [Factory.url, nil].sample
      @router = @router_class.new{ base_url a_base_url }
    end
    subject{ @router }

    should have_readers :request_types, :urls, :routes, :definitions
    should have_readers :trailing_slashes, :escape_query_value_proc

    should have_imeths :view_handler_ns
    should have_imeths :allow_trailing_slashes, :allow_trailing_slashes_set?
    should have_imeths :remove_trailing_slashes, :remove_trailing_slashes_set?
    should have_imeths :trailing_slashes_set?
    should have_imeths :escape_query_value
    should have_imeths :base_url, :set_base_url, :prepend_base_url
    should have_imeths :url, :url_for
    should have_imeths :default_request_type_name, :add_request_type
    should have_imeths :request_type_name
    should have_imeths :get, :post, :put, :patch, :delete
    should have_imeths :route, :redirect, :not_found
    should have_imeths :apply_definitions!, :validate!
    should have_imeths :validate_trailing_slashes!

    should "default its attrs" do
      router = @router_class.new
      assert_nil router.view_handler_ns
      assert_nil router.trailing_slashes
      assert_nil router.base_url
      assert_empty router.request_types
      assert_empty router.urls
      assert_empty router.routes
      assert_empty router.definitions

      exp = @router_class::DEFAULT_REQUEST_TYPE_NAME
      assert_equal exp, router.default_request_type_name

      value = "#%&?"
      exp = Rack::Utils.escape(value)
      assert_equal exp, router.escape_query_value_proc.call(value)
    end

    should "instance eval any given block" do
      ns = Factory.string
      router = Deas::Router.new do
        view_handler_ns ns
      end

      assert_equal ns, router.view_handler_ns
    end

    should "set a view handler namespace" do
      subject.view_handler_ns(exp = Factory.string)
      assert_equal exp, subject.view_handler_ns
    end

    should "config trailing slash handling" do
      assert_false subject.allow_trailing_slashes_set?
      assert_false subject.remove_trailing_slashes_set?
      assert_false subject.trailing_slashes_set?

      subject.allow_trailing_slashes

      assert_equal subject.class::ALLOW_TRAILING_SLASHES, subject.trailing_slashes
      assert_true  subject.allow_trailing_slashes_set?
      assert_false subject.remove_trailing_slashes_set?
      assert_true  subject.trailing_slashes_set?

      subject.remove_trailing_slashes

      assert_equal subject.class::REMOVE_TRAILING_SLASHES, subject.trailing_slashes
      assert_false subject.allow_trailing_slashes_set?
      assert_true  subject.remove_trailing_slashes_set?
      assert_true  subject.trailing_slashes_set?
    end

    should "allow configuring a custom escape query value proc" do
      escape_proc = proc{ Factory.string }
      subject.escape_query_value(&escape_proc)
      assert_equal escape_proc, subject.escape_query_value_proc

      assert_raises(ArgumentError){ subject.escape_query_value }
    end

    should "add get, post, put, patch and delete route definitions" do
      path = Factory.path
      args = [Factory.string]

      [:get, :post, :put, :patch, :delete].each do |meth|
        subject.send(meth, path, *args)
        d = DefinitionSpy.new(*subject.definitions.last)
        assert_equal :route,              d.type
        assert_equal [meth, path, *args], d.args
        assert_equal nil,                 d.block
      end
    end

    should "add redirect definitions" do
      from_path = Factory.path
      to_path   = Factory.path
      block     = proc{}

      subject.redirect(from_path, to_path, &block)
      d = DefinitionSpy.new(*subject.definitions.last)
      assert_equal :redirect,            d.type
      assert_equal [from_path, to_path], d.args
      assert_equal block,                d.block

      subject.redirect(from_path, to_path)
      d = DefinitionSpy.new(*subject.definitions.last)
      assert_equal :redirect,            d.type
      assert_equal [from_path, to_path], d.args
      assert_equal nil,                  d.block

      subject.redirect(from_path)
      d = DefinitionSpy.new(*subject.definitions.last)
      assert_equal :redirect,        d.type
      assert_equal [from_path, nil], d.args
      assert_equal nil,              d.block
    end

    should "add not found definitions" do
      from_path = Factory.path
      body      = Factory.string

      subject.not_found(from_path, body)

      args = [404, {}, body]
      d = DefinitionSpy.new(*subject.definitions.last)
      assert_equal :respond_with,     d.type
      assert_equal [from_path, args], d.args
      assert_equal nil,               d.block
    end

    should "add a route for every definition when applying defintions" do
      subject.set_base_url(nil)

      path1 = Factory.path
      path2 = Factory.path
      subject.get(path1)
      subject.redirect(path1, path2)
      subject.not_found(path1)

      assert_not_empty subject.definitions
      assert_empty     subject.routes

      subject.apply_definitions!
      assert_equal 3, subject.routes.size
      assert_empty subject.definitions

      get = subject.routes[0]
      assert_equal path1, get.path

      redir = subject.routes[1]
      assert_equal path1, redir.path

      nf = subject.routes[2]
      assert_equal path1, nf.path
    end

    should "validate trailing slashes" do
      router = @router_class.new
      router.get('/',           'EmptyViewHandler')
      router.get('/something',  'EmptyViewHandler')
      router.get('/something/', 'EmptyViewHandler')
      router.apply_definitions!

      assert_nothing_raised do
        router.validate_trailing_slashes!
      end

      router.allow_trailing_slashes
      assert_nothing_raised do
        router.validate_trailing_slashes!
      end

      router.remove_trailing_slashes
      err = assert_raises(TrailingSlashesError) do
        router.validate_trailing_slashes!
      end
      exp = "all route paths must *not* end with a \"/\", but these do:\n/something/"
      assert_includes exp, err.message

      router = @router_class.new
      router.get('/',                'EmptyViewHandler')
      router.get('/something/',      'EmptyViewHandler')
      router.get('/something-else/', 'EmptyViewHandler')
      router.apply_definitions!

      assert_nothing_raised do
        router.validate_trailing_slashes!
      end

      router.allow_trailing_slashes
      assert_nothing_raised do
        router.validate_trailing_slashes!
      end

      router.remove_trailing_slashes
      err = assert_raises(TrailingSlashesError) do
        router.validate_trailing_slashes!
      end
      exp = "all route paths must *not* end with a \"/\", but these do:\n"\
            "/something/\n/something-else/"
      assert_includes exp, err.message

      router = @router_class.new
      router.get('/',               'EmptyViewHandler')
      router.get('/something',      'EmptyViewHandler')
      router.get('/something-else', 'EmptyViewHandler')
      router.apply_definitions!

      assert_nothing_raised do
        router.validate_trailing_slashes!
      end

      router.allow_trailing_slashes
      assert_nothing_raised do
        router.validate_trailing_slashes!
      end

      router.remove_trailing_slashes
      assert_nothing_raised do
        router.validate_trailing_slashes!
      end
    end

    should "apply definitions and validate each route when validating" do
      subject.get('/something', 'EmptyViewHandler')
      subject.apply_definitions!
      subject.validate_trailing_slashes!
      route = subject.routes.last
      proxy = route.handler_proxies[subject.default_request_type_name]

      apply_def_called = false
      Assert.stub(subject, :apply_definitions!){ apply_def_called = true }

      val_trailing_called = false
      Assert.stub(subject, :validate_trailing_slashes!){ val_trailing_called = true }

      assert_false apply_def_called
      assert_false val_trailing_called
      assert_nil proxy.handler_class

      subject.validate!

      assert_true apply_def_called
      assert_true val_trailing_called
      assert_equal EmptyViewHandler, proxy.handler_class
    end

    should "set a base url" do
      subject.base_url(exp = Factory.url)
      assert_equal exp, subject.base_url

      subject.base_url(nil)
      assert_not_nil subject.base_url

      subject.set_base_url(nil)
      assert_nil subject.base_url
    end

    should "prepend the base url to any url path" do
      subject.set_base_url(nil)
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
      subject.get(path); subject.apply_definitions!
      route = subject.routes.last

      exp_path = subject.prepend_base_url(path)
      assert_equal exp_path, route.path
    end

    should "prepend the base url when adding redirects" do
      url = Factory.url
      subject.base_url url
      path1 = Factory.path
      path2 = Factory.path
      subject.redirect(path1, path2); subject.apply_definitions!
      redirect = subject.routes.last

      exp = subject.prepend_base_url(path1)
      assert_equal exp, redirect.path

      proxy = redirect.handler_proxies[subject.default_request_type_name]
      handler = test_handler(proxy.handler_class)
      exp = subject.prepend_base_url(path2)
      assert_equal exp, handler.redirect_location
    end

    should "prepend the base url when adding not founds" do
      url = Factory.url
      subject.base_url url
      path = Factory.path
      subject.not_found(path); subject.apply_definitions!
      route = subject.routes.last

      exp_path = subject.prepend_base_url(path)
      assert_equal exp_path, route.path
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

      subject.route(@method, @path1); subject.apply_definitions!
      assert_not_empty subject.routes

      route = subject.routes.last
      assert_instance_of Deas::Route, route
      assert_equal @method, route.method
      assert_equal subject.prepend_base_url(@path1), route.path

      proxies = route.handler_proxies
      assert_kind_of HandlerProxies, proxies
      assert_empty proxies
      assert_equal subject.default_request_type_name, proxies.default_type
    end

    should "proxy any handler class given for the default request type" do
      subject.route(@method, @path1, @handler_class_name1); subject.apply_definitions!
      route = subject.routes.last
      proxy = route.handler_proxies[subject.default_request_type_name]
      assert_kind_of Deas::RouteProxy, proxy
      assert_equal @handler_class_name1, proxy.handler_class_name

      subject.route(@method, @path1, @handler_class_name1, {
        subject.default_request_type_name => @handler_class_name2
      }); subject.apply_definitions!
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
      }); subject.apply_definitions!
      route = subject.routes.last

      proxy = route.handler_proxies['1']
      assert_kind_of Deas::RouteProxy, proxy
      assert_equal @handler_class_name1, proxy.handler_class_name

      proxy = route.handler_proxies['2']
      assert_kind_of Deas::RouteProxy, proxy
      assert_equal @handler_class_name2, proxy.handler_class_name
    end

    should "add redirect routes" do
      subject.redirect(@path1, @path2); subject.apply_definitions!

      route = subject.routes.last
      assert_instance_of Deas::Route, route
      assert_equal :get, route.method
      assert_equal subject.prepend_base_url(@path1), route.path

      proxy = route.handler_proxies[subject.default_request_type_name]
      assert_kind_of Deas::RedirectProxy, proxy
      assert_equal 'Deas::RedirectHandler', proxy.handler_class_name

      handler = test_handler(proxy.handler_class)
      exp = subject.prepend_base_url(@path2)
      assert_equal exp, handler.redirect_location
    end

    should "add not found routes" do
      subject.not_found(@path1); subject.apply_definitions!

      route = subject.routes.last
      assert_instance_of Deas::Route, route
      assert_equal :get, route.method
      assert_equal subject.prepend_base_url(@path1), route.path

      proxy = route.handler_proxies[subject.default_request_type_name]
      assert_kind_of Deas::RespondWithProxy, proxy
      assert_equal 'Deas::RespondWithHandler', proxy.handler_class_name

      handler = test_handler(proxy.handler_class)
      assert_equal [404, {}, 'Not Found'], handler.halt_args

      body = Factory.string
      subject.not_found(@path1, body); subject.apply_definitions!

      route   = subject.routes.last
      proxy   = route.handler_proxies[subject.default_request_type_name]
      handler = test_handler(proxy.handler_class)
      assert_equal [404, {}, body], handler.halt_args
    end

    should "complain if adding a route with invalid splats in its path" do
      [ "/something/other*/",
        "/something/other*",
        "/something/*other",
        "/something*/other",
        "/*something/other",
        "/something/*/other/*",
        "/something/*/other",
        "/something/*/",
        "/*/something",
      ].each do |path|
        assert_raises InvalidSplatError do
          router = @router_class.new
          router.route(:get, path)
          router.apply_definitions!
        end
      end

      [ "/something/*",
        "/*"
      ].each do |path|
        assert_nothing_raised do
          router = @router_class.new
          router.route(:get, path)
          router.apply_definitions!
        end
      end
    end

  end

  class NamedUrlTests < InitTests
    setup do
      @router.url(:get_info, '/info/:for')
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
      name = Factory.string.to_sym
      escape_proc = proc{ Factory.string }
      @router.url(name, Factory.path, :escape_query_value => escape_proc)

      url = subject.urls[name]
      assert_equal escape_proc, url.escape_query_value_proc
    end

    should "complain if defining a url with a non-symbol name" do
      assert_raises ArgumentError do
        subject.url('get_info', '/info')
      end
    end

    should "complain if defining a url with a non-string path" do
      assert_raises ArgumentError do
        subject.url(:get_info, /^\/info/)
      end
    end

    should "build a path for a url given params" do
      exp_path = subject.prepend_base_url("/info/now")
      assert_equal exp_path, subject.url_for(:get_info, :for => 'now')
    end

    should "'squash' duplicate forward-slashes when building urls" do
      exp_path = subject.prepend_base_url("/info/now")
      assert_equal exp_path, subject.url_for(:get_info, :for => '/now')
    end

    should "complain if buiding a named url with non-hash params" do
      assert_raises ArgumentError do
        subject.url_for(:get_info, ['now', :now, nil].sample)
      end
    end

    should "complain if given an empty named param value" do
      assert_raises ArgumentError do
        subject.url_for(:get_info, :for => [nil, ''].sample)
      end
    end

    should "complain if building a named url that hasn't been defined" do
      assert_raises ArgumentError do
        subject.url_for(:not_defined_url)
      end
    end

    should "complain if routing a named url that hasn't been defined" do
      assert_raises ArgumentError do
        subject.route(:get, :not_defined_url, 'GetInfo')
        subject.apply_definitions!
      end
    end

    should "route using a url name instead of a path" do
      subject.route(:get, :get_info, 'GetInfo'); subject.apply_definitions!

      url   = subject.urls[:get_info]
      route = subject.routes.last

      exp = subject.prepend_base_url(url.path)
      assert_equal exp, route.path
    end

    should "complain if redirecting to/from a named url that hasn't been defined" do
      assert_raises ArgumentError do
        subject.redirect('/somewhere', :not_defined_url)
        subject.apply_definitions!
      end
      assert_raises ArgumentError do
        subject.redirect(:not_defined_url, '/somewhere')
        subject.apply_definitions!
      end
    end

    should "redirect using a url name instead of a path" do
      subject.redirect(:get_info, '/somewhere'); subject.apply_definitions!

      url   = subject.urls[:get_info]
      route = subject.routes.last

      exp = subject.prepend_base_url(url.path)
      assert_equal exp, route.path
    end

    should "complain if adding a not found with a named url that hasn't been defined" do
      assert_raises ArgumentError do
        subject.not_found(:not_defined_url)
        subject.apply_definitions!
      end
    end

    should "add a not found using a url name instead of a path" do
      subject.not_found(:get_info); subject.apply_definitions!

      url   = subject.urls[:get_info]
      route = subject.routes.last

      exp = subject.prepend_base_url(url.path)
      assert_equal exp, route.path
    end

    should "prepend the base url when building named urls" do
      url = Factory.url
      subject.base_url url
      path = Factory.path
      subject.url(:base_get_info, path)

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

  DefinitionSpy = Struct.new(:type, :args, :block)
end

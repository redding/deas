require 'assert'
require 'sinatra/base'
require 'test/support/view_handlers'
require 'deas/route_proxy'
require 'deas/route'
require 'deas/router'
require 'deas/server'
require 'deas/sinatra_app'

module Deas::SinatraApp

  class UnitTests < Assert::Context
    desc "Deas::SinatraApp"
    setup do
      proxy = Deas::RouteProxy.new('TestViewHandler')
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
        c.router           = @router
      end
      @sinatra_app = Deas::SinatraApp.new(@configuration)
    end
    subject{ @sinatra_app }

    should "ensure its config is valid" do
      assert @configuration.valid?
    end

    should "be a kind of Sinatra::Base" do
      assert_equal Sinatra::Base, subject.superclass
    end

    should "have it's configuration set based on the server configuration" do
      subject.settings.tap do |settings|
        assert_equal 'staging',                  settings.environment
        assert_equal 'path/to/somewhere',        settings.root.to_s
        assert_equal 'path/to/somewhere/public', settings.public_folder.to_s
        assert_equal 'path/to/somewhere/views',  settings.views.to_s
        assert_equal true,                       settings.dump_errors
        assert_equal false,                      settings.method_override
        assert_equal false,                      settings.sessions
        assert_equal true,                       settings.static
        assert_equal true,                       settings.reload_templates
        assert_instance_of Deas::NullLogger,     settings.logger
        assert_instance_of Deas::Router,         settings.router

        # settings that are set but can't be changed
        assert_equal false, settings.logging
        assert_equal false, settings.raise_errors
        assert_equal false, settings.show_exceptions
      end
    end

    should "define Sinatra routes for every route in the configuration" do
      get_routes = subject.routes[@route.method.to_s.upcase] || []
      sinatra_route = get_routes.detect{ |route| route[0].match(@route.path) }

      assert_not_nil sinatra_route
    end

  end

end

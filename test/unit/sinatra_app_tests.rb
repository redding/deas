require 'assert'
require 'deas/sinatra_app'

require 'sinatra/base'
require 'deas/logger'
require 'deas/route_proxy'
require 'deas/route'
require 'deas/router'
require 'deas/server'
require 'deas/server_data'
require 'test/support/view_handlers'

module Deas::SinatraApp

  class UnitTests < Assert::Context
    desc "Deas::SinatraApp"
    setup do
      @router = Deas::Router.new
      @router.get('/something', 'EmptyViewHandler')
      @router.validate!

      @configuration = Deas::Server::Configuration.new.tap do |c|
        c.env              = 'staging'
        c.root             = 'path/to/somewhere'
        c.dump_errors      = true
        c.method_override  = false
        c.sessions         = false
        c.show_exceptions  = true
        c.static           = true
        c.reload_templates = true
        c.default_encoding = 'latin1'
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
        assert_equal 'latin1',                   settings.default_encoding

        # settings that are set but can't be changed
        assert_equal false, settings.logging
        assert_equal false, settings.raise_errors
        assert_equal false, settings.show_exceptions

        exp = Deas::ServerData.new(@configuration.to_hash)
        sd = settings.deas_server_data
        assert_instance_of Deas::ServerData,          sd
        assert_instance_of exp.template_source.class, sd.template_source
        assert_instance_of exp.logger.class,          sd.logger
        assert_equal exp.error_procs, sd.error_procs
        assert_equal exp.router,      sd.router

        assert_includes "application/json", settings.add_charset
      end
    end

    should "define Sinatra routes for every route in the configuration" do
      router_route   = @router.routes.last
      sinatra_routes = subject.routes[router_route.method.to_s.upcase] || []

      assert_not_nil sinatra_routes.detect{ |r| r[0].match(router_route.path) }
    end

  end

end

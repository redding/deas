require 'assert'
require 'deas/sinatra_app'

require 'sinatra/base'
require 'deas/logger'
require 'deas/route_proxy'
require 'deas/route'
require 'deas/router'
require 'deas/server'
require 'deas/server_data'
require 'test/support/empty_view_handler'

module Deas::SinatraApp

  class UnitTests < Assert::Context
    desc "Deas::SinatraApp"
    subject{ Deas::SinatraApp }

    should have_imeths :new

    should "know its default error response status" do
      assert_equal 500, subject::DEFAULT_ERROR_RESPONSE_STATUS
    end

    should "know its standard error classes" do
      exp = [StandardError, LoadError, NotImplementedError, Timeout::Error]
      assert_equal exp, subject::STANDARD_ERROR_CLASSES
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @router = Deas::Router.new
      @router.get('/something', 'EmptyViewHandler')
      @router.validate!

      # set config attributes to make sure they are passed to the `ServerData`
      @config = Deas::Server::Config.new.tap do |c|
        c.error_procs            = Factory.integer(3).times.map{ proc{ Factory.string } },
        c.before_route_run_procs = Factory.integer(3).times.map{ proc{ Factory.string } },
        c.after_route_run_procs  = Factory.integer(3).times.map{ proc{ Factory.string } },
        c.template_source        = Factory.string,
        c.logger                 = Factory.string,
        c.router                 = @router
      end

      @sinatra_app = Deas::SinatraApp.new(@config)
    end
    subject{ @sinatra_app }

    should "ensure its config is valid" do
      assert @config.valid?
    end

    should "be a kind of Sinatra::Base app" do
      assert_equal Sinatra::Base, subject.superclass
    end

    should "have it's configuration set based on the server config or defaults" do
      s = subject.settings

      assert_equal @config.env,  s.environment
      assert_equal @config.root, s.root

      assert_equal @config.root, s.views
      assert_equal @config.root, s.public_folder
      assert_equal 'utf-8',      s.default_encoding

      assert_false s.method_override
      assert_false s.reload_templates
      assert_false s.static
      assert_false s.sessions
      assert_false s.protection
      assert_false s.raise_errors
      assert_false s.show_exceptions
      assert_false s.dump_errors
      assert_false s.logging
    end

    should "define Sinatra routes for every route in the configuration" do
      router_route   = @router.routes.last
      sinatra_routes = subject.routes[router_route.method.to_s.upcase] || []

      assert_not_nil sinatra_routes.detect{ |r| r[0].match(router_route.path) }
    end

    # System tests ensure that routes get applied to the sinatra app correctly.

  end

end

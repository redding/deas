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
    setup do
      @router = Deas::Router.new
      @router.get('/something', 'EmptyViewHandler')
      @router.validate!

      @config = Deas::Server::Config.new
      @config.router = @router

      @sinatra_app = Deas::SinatraApp.new(@config)
    end
    subject{ @sinatra_app }

    should "ensure its config is valid" do
      assert @config.valid?
    end

    should "be a kind of Sinatra::Base" do
      assert_equal Sinatra::Base, subject.superclass
    end

    should "have it's configuration set based on the server config" do
      s = subject.settings

      assert_equal @config.env,              s.environment
      assert_equal @config.root,             s.root
      assert_equal @config.views_root,       s.views
      assert_equal @config.public_root,      s.public_folder
      assert_equal @config.default_encoding, s.default_encoding
      assert_equal @config.dump_errors,      s.dump_errors
      assert_equal @config.method_override,  s.method_override
      assert_equal @config.reload_templates, s.reload_templates
      assert_equal @config.sessions,         s.sessions
      assert_equal @config.static_files,     s.static

      assert_equal false, s.raise_errors
      assert_equal false, s.show_exceptions
      assert_equal false, s.logging

      exp = Deas::ServerData.new({
        :error_procs     => @config.error_procs,
        :logger          => @config.logger,
        :router          => @config.router,
        :template_source => @config.template_source
      })
      sd = s.deas_server_data
      assert_instance_of Deas::ServerData, sd
      assert_instance_of exp.template_source.class, sd.template_source
      assert_instance_of exp.logger.class, sd.logger
      assert_equal exp.error_procs, sd.error_procs
      assert_equal exp.router,      sd.router

      assert_includes "application/json", s.add_charset
    end

    should "define Sinatra routes for every route in the configuration" do
      router_route   = @router.routes.last
      sinatra_routes = subject.routes[router_route.method.to_s.upcase] || []

      assert_not_nil sinatra_routes.detect{ |r| r[0].match(router_route.path) }
    end

  end

end

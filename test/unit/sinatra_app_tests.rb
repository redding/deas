require 'assert'
require 'deas/route'
require 'deas/server'
require 'deas/sinatra_app'
require 'sinatra/base'
require 'test/support/view_handlers'

module Deas::SinatraApp

  class BaseTests < Assert::Context
    desc "Deas::SinatraApp"
    setup do
      @route = Deas::Route.new(:get, '/something', 'TestViewHandler')
      @configuration = Deas::Server::Configuration.new.tap do |c|
        c.env             = 'staging'
        c.root            = 'path/to/somewhere'
        c.dump_errors     = true
        c.method_override = false
        c.sessions        = false
        c.static          = true
        c.routes          = [ @route ]
      end
      @sinatra_app = Deas::SinatraApp.new(@configuration)
    end
    subject{ @sinatra_app }

    should "be a kind of Sinatra::Base" do
      assert_equal Sinatra::Base, subject.superclass
    end

    should "call init procs when initialized" do
      initialized = false
      @configuration.init_proc = proc{ initialized = true }
      @sinatra_app = Deas::SinatraApp.new(@configuration)

      assert_equal true, initialized
    end

    should "call constantize! on all routes" do
      assert_equal TestViewHandler, @route.handler_class
    end

    should "have it's configuration set based on the server configuration" do
      subject.settings do |settings|
        assert_equal 'staging',                  settings.env
        assert_equal 'path/to/somewhere',        settings.root
        assert_equal @configuration.app_file,    settings.app_file
        assert_equal 'path/to/somewhere/public', settings.public_folder
        assert_equal 'path/to/somewhere/views',  settings.views
        assert_equal true,                       settings.dump_errors
        assert_equal false,                      settings.logging
        assert_equal false,                      settings.method_override
        assert_equal false,                      settings.sessions
        assert_equal true,                       settings.static_files
        assert_equal @configuration.logger,      settings.deas_logger
      end
    end

    should "define Sinatra routes for every route in the configuration" do
      get_routes = subject.routes[@route.method.to_s.upcase] || []
      sinatra_route = get_routes.detect{|route| route[0].match(@route.path) }

      assert_not_nil sinatra_route
    end

  end

end

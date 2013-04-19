require 'assert'
require 'deas/server'
require 'deas/sinatra_app'

module Deas::SinatraApp

  class BaseTests < Assert::Context
    desc "Deas::SinatraApp"
    setup do
      @configuration = Deas::Server::Configuration.new
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

    should "have it's configuration set based on the server configuration" do
      subject.settings do |settings|
        assert_equal @configuration.env,             settings.env
        assert_equal @configuration.root,            settings.root
        assert_equal @configuration.app_file,        settings.app_file
        assert_equal @configuration.public_folder,   settings.public_folder
        assert_equal @configuration.views_folder,    settings.views
        assert_equal @configuration.dump_errors,     settings.dump_errors
        assert_equal @configuration.logging,         false
        assert_equal @configuration.method_override, settings.method_override
        assert_equal @configuration.sessions,        settings.sessions
        assert_equal @configuration.static,          settings.static_files
      end
    end

  end

end

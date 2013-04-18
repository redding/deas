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

  end

end

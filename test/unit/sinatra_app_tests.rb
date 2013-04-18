require 'assert'
require 'deas/sinatra_app'

module Deas::SinatraApp

  class BaseTests < Assert::Context
    desc "Deas::SinatraApp"
    setup do
      @sinatra_app = Deas::SinatraApp.new(Deas::Server)
    end
    subject{ @sinatra_app }

    should "be a kind of Sinatra::Base" do
      assert_equal Sinatra::Base, subject.superclass
    end

  end

end

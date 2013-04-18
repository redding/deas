require 'assert'
require 'deas/server'

class Deas::Server

  class BaseTests < Assert::Context
    desc "Deas::Server"
    subject{ Deas::Server }

    should "be a singleton" do
      assert_includes Singleton, subject.included_modules
    end

  end

end

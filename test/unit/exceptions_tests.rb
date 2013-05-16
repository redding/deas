require 'assert'
require 'deas/exceptions'

module Deas

  class ErrorTests < Assert::Context
    desc "Deas"

    should "provide an error exception that subclasses `RuntimeError" do
      assert Deas::Error
      assert_kind_of RuntimeError, Deas::Error.new
    end

    should "provide a server exception that subclasses `Error`" do
      assert Deas::ServerError
      assert_kind_of Deas::Error, Deas::ServerError.new
    end

    should "provide a server root exception that subclasses `ServerError`" do
      assert Deas::ServerRootError

      e = Deas::ServerRootError.new
      assert_kind_of Deas::ServerError, e
      assert_equal "server `root` not set but required", e.message
    end

  end

end

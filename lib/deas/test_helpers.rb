require 'deas/test_runner'

module Deas

  module TestHelpers

    module_function

    def test_runner(handler_class, args = nil)
      TestRunner.new(handler_class, args)
    end

    def test_handler(handler_class, args = nil)
      test_runner(handler_class, args).handler
    end

  end

end

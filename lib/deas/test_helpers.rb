require 'deas/test_runner'

module Deas

  module TestHelpers

    module_function

    def test_runner(handler_class, args = nil)
      TestRunner.new(handler_class, args)
    end

  end

end

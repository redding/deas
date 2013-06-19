require 'assert'
require 'deas/test_helpers'
require 'test/support/view_handlers'
require 'deas/route_proxy'

class Deas::RouteProxy

  class BaseTests < Assert::Context
    desc "Deas::RouteProxy"
    setup do
      @proxy = Deas::RouteProxy.new('TestViewHandler')
    end
    subject{ @proxy }

    should have_reader :handler_class_name
    should have_imeths :handler_class

    should "know its handler class name" do
      assert_equal 'TestViewHandler', subject.handler_class_name
    end

    should "know its handler class" do
      assert_equal TestViewHandler, subject.handler_class
    end

    should "complain if there is no handler class with the given name" do
      assert_raises(Deas::NoHandlerClassError) do
        Deas::RouteProxy.new('SomethingNotDefined').handler_class
      end
    end

  end

end

require 'assert'
require 'deas/route'
require 'deas/sinatra_runner'
require 'test/support/fake_sinatra_call'
require 'test/support/view_handlers'

class Deas::Route

  class BaseTests < Assert::Context
    desc "Deas::Route"
    setup do
      @route = Deas::Route.new(:get, '/test', 'TestViewHandler')
    end
    subject{ @route }

    should have_instance_methods :method, :path, :handler_class_name,
      :handler_class, :run

    should "allow passing a constantized handler when initialized" do
      route = Deas::Route.new(:get, '/test', 'TestViewHandler', TestViewHandler)

      # handler class is set without calling constantize
      assert_equal TestViewHandler, route.handler_class
    end

    should "constantize the handler class with #constantize!" do
      assert_nil subject.handler_class

      assert_nothing_raised{ subject.constantize! }

      assert_equal TestViewHandler, subject.handler_class
    end

    should "raise a custom exception if the handler class name " \
           "can't be constantized" do
      route = Deas::Route.new(:get, '/', 'SomethingNotDefined')

      assert_raises(Deas::NoHandlerClassError) do
        route.constantize!
      end
    end

  end

end

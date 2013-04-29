require 'assert'
require 'deas/route'
require 'deas/sinatra_runner'
require 'test/support/fake_app'
require 'test/support/view_handlers'

class Deas::Route

  class BaseTests < Assert::Context
    desc "Deas::Route"
    setup do
      @route = Deas::Route.new(:get, '/test', 'TestViewHandler')
    end
    subject{ @route }

    should have_instance_methods :method, :path, :handler_class_name,
      :handler_class, :runner

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

    should "return an instance of the Runner class with supplied variables" do
      subject.constantize!
      returned = subject.runner(FakeApp.new)
      assert_instance_of Deas::SinatraRunner, returned
    end
  end

end

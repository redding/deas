require 'assert'
require 'deas/runner'

require 'test/support/view_handlers'

class Deas::Runner

  class BaseTests < Assert::Context
    desc "Deas::Runner"
    setup do
      @runner = Deas::Runner.new(TestViewHandler)
    end
    subject{ @runner }

    should have_readers :handler_class, :handler
    should have_readers :request, :response, :params, :logger, :session
    should have_imeths :halt, :redirect, :content_type, :status, :headers
    should have_imeths :render, :send_file

    should "know its handler and handler class" do
      assert_equal TestViewHandler, subject.handler_class
      assert_instance_of subject.handler_class, subject.handler
    end

    should "not set any settings" do
      assert_nil subject.request
      assert_nil subject.response
      assert_nil subject.params
      assert_nil subject.logger
      assert_nil subject.session
    end

    should "not implement any actions" do
      assert_raises(NotImplementedError){ subject.halt }
      assert_raises(NotImplementedError){ subject.redirect }
      assert_raises(NotImplementedError){ subject.content_type }
      assert_raises(NotImplementedError){ subject.status }
      assert_raises(NotImplementedError){ subject.headers }
      assert_raises(NotImplementedError){ subject.render }
      assert_raises(NotImplementedError){ subject.send_file }
    end

  end

end

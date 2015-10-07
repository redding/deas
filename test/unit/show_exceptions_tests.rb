require 'assert'
require 'deas/show_exceptions'

require 'rack/utils'

class Deas::ShowExceptions

  class UnitTests < Assert::Context
    desc "Deas::ShowExceptions"
    setup do
      @middleware_class = Deas::ShowExceptions
    end
    subject{ @middleware_class }

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @app = Factory.sinatra_call
      @env = { 'sinatra.error' => Factory.exception }
      @middleware = @middleware_class.new(@app)
    end
    subject{ @middleware }

    should have_imeths :call, :call!

    should "return a response for the exception when called" do
      status, headers, body = subject.call(@env)
      error_body = Body.new(@env['sinatra.error'])

      assert_equal @app.response.status, status
      assert_equal error_body.size.to_s, headers['Content-Length']
      assert_equal error_body.mime_type, headers['Content-Type']
      assert_equal [error_body.content], body
    end

    should "return the apps response if there isn't an exception" do
      @env.delete('sinatra.error')
      status, headers, body = subject.call(@env)

      assert_equal @app.response.status,  status
      assert_equal @app.response.headers, headers
      assert_equal [@app.response.body],  body
    end

  end

  class BodyTests < UnitTests
    desc "Body"
    setup do
      @exception = Factory.exception
      @body = Body.new(@exception)
    end
    subject{ @body }

    should have_readers :content, :size, :mime_type

    should "know its attributes" do
      exp_content = "#{@exception.class}: #{@exception.message}\n" \
                "#{@exception.backtrace.join("\n")}"
      assert_equal exp_content, subject.content
      assert_equal Rack::Utils.bytesize(exp_content), subject.size
      assert_equal "text/plain", subject.mime_type
    end

  end

end

require 'assert'
require 'rack/utils'
require 'deas/show_exceptions'

class Deas::ShowExceptions

  class UnitTests < Assert::Context
    desc "Deas::ShowExceptions"
    setup do
      exception = Sinatra::NotFound.new
      @app = proc do |env|
        env['sinatra.error'] = exception
        [ 404, {}, [] ]
      end
      @exception = exception
      @show_exceptions = Deas::ShowExceptions.new(@app)
    end
    subject{ @show_exceptions }

    should have_imeths :call, :call!

    should "return a body that contains details about the exception" do
      status, headers, body = subject.call({})
      expected_body = "#{@exception.class}: #{@exception.message}\n" \
                      "#{(@exception.backtrace || []).join("\n")}"
      expected_body_size = Rack::Utils.bytesize(expected_body).to_s

      assert_equal expected_body_size, headers['Content-Length']
      assert_equal "text/plain",       headers['Content-Type']
      assert_equal [expected_body],    body
    end

  end

end

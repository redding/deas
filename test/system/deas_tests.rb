require 'assert'
require 'deas'

require 'assert-rack-test'

module Deas

  class RackTestsContext < Assert::Context
    include Assert::Rack::Test

    def app; @app; end
  end

  class RackTests < RackTestsContext
    desc "a Deas server rack app"
    setup do
      @app = DeasTestServer.new
    end

    should "return a 200 response with a GET to '/show'" do
      get '/show', 'message' => 'this is a test'

      assert_equal 200, last_response.status
      assert_equal "this is a test", last_response.body
    end

    should "set the content type appropriately" do
      get '/show'
      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.headers['Content-Type']

      get '/show.html'
      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.headers['Content-Type']

      get '/show.json'
      assert_equal 200, last_response.status
      assert_equal 'application/json;charset=utf-8', last_response.headers['Content-Type']

      get '/show-latin1-json'
      assert_equal 200, last_response.status
      assert_equal 'application/json;charset=latin1', last_response.headers['Content-Type']

      get '/show-text'
      assert_equal 200, last_response.status
      assert_equal 'text/plain', last_response.headers['Content-Type']

      get '/show-headers-text'
      assert_equal 200, last_response.status
      assert_equal 'text/plain', last_response.headers['Content-Type']
    end

    should "render different handlers for the same meth/path based on the type" do
      get '/req-type-show/regular', 'message' => 'this is a test request'
      assert_equal 200, last_response.status
      assert_equal "this is a test request", last_response.body

      get '/req-type-show/mobile', 'message' => 'this is a test request'
      assert_equal 200, last_response.status
      assert_equal "[MOBILE] this is a test request", last_response.body

      get '/req-type-show/other', 'message' => 'this is a test request'
      assert_equal 404, last_response.status
    end

    should "allow halting with a custom response" do
      get '/halt', 'with' => 234

      assert_equal 234, last_response.status
    end

    should "return a 404 response with an undefined route and " \
           "run the defined error procs" do
      get '/not_defined'

      assert_equal 404, last_response.status
      assert_equal "Couldn't be found", last_response.body
    end

    should "return a 500 response with an error route and " \
           "run the defined error procs" do
      get '/error'

      assert_equal 500, last_response.status
      assert_equal "Oops, something went wrong", last_response.body
    end

    should "return a 302 redirecting to the expected locations" do
      get '/redirect'
      exp_location = 'http://google.com'

      assert_equal 302, last_response.status
      assert_equal exp_location, last_response.headers['Location']
    end

    should "return a 302 redirect to the expected location " \
           "when using a route redirect" do
      get '/route_redirect'
      exp_location = 'http://example.org/somewhere'

      assert_equal 302, last_response.status
      assert_equal exp_location, last_response.headers['Location']

      get '/my_prefix/redirect'
      exp_location = 'http://example.org/my_prefix/somewhere'

      assert_equal 302, last_response.status
      assert_equal exp_location, last_response.headers['Location']
    end

  end

  class SessionTests < RackTests
    desc "using sessions"

    should "return a 200 response and the session value" do
      post '/session'
      follow_redirect!

      assert_equal 200,              last_response.status
      assert_equal 'session_secret', last_response.body
    end

  end

  class HandlerTests < RackTests
    desc "handler"
    setup do
      get 'handler/tests?a-param=something'
      @data_inspect = last_response.body
    end

    should "be able to access sinatra call data" do
      exp = {
        'logger_class_name' => 'Logger',
        'request_method'    => 'GET',
        'params_a_param'    => 'something'
      }
      assert_equal exp.inspect, @data_inspect
    end

  end

  class ShowExceptionsTests < RackTestsContext
    desc "a Deas server rack app with show exceptions enabled"
    setup do
      @app = DeasDevServer.new
    end

    should "return a text/plain body when a 404 occurs" do
      get '/not_defined'

      assert_equal 404, last_response.status
      assert_equal "text/plain", last_response.headers['Content-Type']
      assert_match "Deas::NotFound: GET /not_defined", last_response.body
    end

    should "return a text/plain body when an exception occurs" do
      get '/error'

      assert_equal 500, last_response.status
      assert_equal "text/plain", last_response.headers['Content-Type']
      assert_match "sinatra app standard error", last_response.body
    end

  end

  class RemoveTrailingSlashesTests < RackTestsContext
    desc "a Deas server rack app with a router that requires no trailing slashes"
    setup do
      @app = RemoveTrailingSlashesServer.new
    end

    should "redirect any paths that end with a slash" do
      get '/show/'

      assert_equal 302,     last_response.status
      assert_equal '/show', last_response.headers['Location']
    end

    should "serve any found paths that do not end with a slash" do
      get '/'
      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.headers['Content-Type']

      get '/show'
      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.headers['Content-Type']
    end

  end

  class AllowTrailingSlashesTests < RackTestsContext
    desc "a Deas server rack app with a router that allows trailing slashes"
    setup do
      @app = AllowTrailingSlashesServer.new
    end

    should "serve any found paths regardless of whether they end with a slash" do
      get '/'
      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.headers['Content-Type']

      get '/show'
      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.headers['Content-Type']

      get '/show/'
      assert_equal 200, last_response.status
      assert_equal 'text/html;charset=utf-8', last_response.headers['Content-Type']

      get '/show-text'
      assert_equal 200, last_response.status
      assert_equal 'text/plain', last_response.headers['Content-Type']

      get '/show-text/'
      assert_equal 200, last_response.status
      assert_equal 'text/plain', last_response.headers['Content-Type']
    end

  end

end

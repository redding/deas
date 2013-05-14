require 'assert'
require 'assert-rack-test'
require 'deas'

module Deas

  class RackTests < Assert::Context
    include Assert::Rack::Test

    desc "a Deas server rack app"
    setup do
      @app = DeasTestServer.new
    end

    def app; @app; end

    should "return a 200 response with a GET to '/show'" do
      get '/show', 'message' => 'this is a test'

      expected_body = "show page: this is a test\n" \
                      "Stuff: Show Info\n"
      assert_equal 200,           last_response.status
      assert_equal expected_body, last_response.body
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

    should "return a 200 response and use all the layouts" do
      get '/with_layout'

      expected_body = "Layout 1\nLayout 2\nLayout 3\nWith Layout\n"
      assert_equal 200,           last_response.status
      assert_equal expected_body, last_response.body

      get '/alt_with_layout'

      assert_equal 200,           last_response.status
      assert_equal expected_body, last_response.body
    end

    should "return a 302 redirecting to the expected locations" do
      get '/redirect'
      expected_location = 'http://google.com'

      assert_equal 302,               last_response.status
      assert_equal expected_location, last_response.headers['Location']
    end

    should "return a 302 redirect to the expected location " \
           "when using a route redirect" do
      get '/route_redirect'
      expected_location = 'http://example.org/somewhere'

      assert_equal 302,               last_response.status
      assert_equal expected_location, last_response.headers['Location']

      get '/my_prefix/redirect'
      expected_location = 'http://example.org/my_prefix/somewhere'

      assert_equal 302,               last_response.status
      assert_equal expected_location, last_response.headers['Location']
    end

  end

  class SessionTests < RackTests
    desc "with sessions enabled"
    setup do
      @orig_sessions = @app.settings.sessions
      @app.set :sessions, true
    end
    teardown do
      @app.set :sessions, @orig_sessions
    end

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
      get 'handler/tests.json?a-param=something'

      require 'multi_json'
      @data = MultiJson.decode(last_response.body || "")
    end

    should "be able to access sinatra call data" do
      assert_equal 'something',    @data['app_settings_a_setting']
      assert_equal 'Logger',       @data['logger_class_name']
      assert_equal 'GET',          @data['request_method']
      assert_equal 'Content-Type', @data['response_firstheaderval']
      assert_equal 'something',    @data['params_a_param']
      assert_equal '{}',           @data['session_inspect']
    end

  end

end
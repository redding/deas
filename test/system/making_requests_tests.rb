require 'assert'
require 'rack/test'

module Deas

  class RackTests < Assert::Context
    include Rack::Test::Methods

    desc "Deas' the rack app"
    setup do
      @app = Deas.app.new
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

      get '/redirect_to'
      expected_location = 'http://example.org/somewhere'

      assert_equal 302,               last_response.status
      assert_equal expected_location, last_response.headers['Location']
    end

  end

  class SessionTests < RackTests
    desc "with sessions enabled"
    setup do
      orig_sessions = Deas.app.settings.sessions
      Deas.app.set :sessions, true
      @app = Deas.app.new
      Deas.app.set :sessions, orig_sessions
    end

    should "return a 200 response and the session value" do
      post '/session'
      follow_redirect!

      assert_equal 200,              last_response.status
      assert_equal 'session_secret', last_response.body
    end

  end

end

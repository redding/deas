require 'assert'
require 'deas/trailing_slashes'

require 'deas/exceptions'
require 'deas/router'
require 'rack/utils'

class Deas::TrailingSlashes

  class UnitTests < Assert::Context
    desc "Deas::TrailingSlashes"
    setup do
      @env = {}

      @middleware_class = Deas::TrailingSlashes
    end
    subject{ @middleware_class }

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @value = Deas::Router::VALID_TRAILING_SLASHES_VALUES.sample

      @handler_run_args = nil
      @handler_run_proc = nil
      Assert.stub(HANDLERS[@value], :run) do |*args, &block|
        @handler_run_args = args
        @handler_run_proc = block
      end

      @app, @router = build_value_app_router(@value)
      @middleware   = @middleware_class.new(@app, @router)
    end
    subject{ @middleware }

    should have_imeths :call, :call!

    should "run a handler based on the router's trailing slashes value when called" do
      subject.call(@env)

      assert_equal [@env], @handler_run_args
      assert_not_nil @handler_run_proc

      status, headers, body = subject.instance_eval(&@handler_run_proc)
      assert_equal @app.response.status,  status
      assert_equal @app.response.headers, headers
      assert_equal [@app.response.body],  body
    end

    should "complain if there is an invalid trailing slashes value set on the router" do
      app, router = build_value_app_router(nil)

      err = assert_raises(ArgumentError){ @middleware_class.new(app, router) }
      exp = "TrailingSlashes middleware is in use but there is no "\
            "trailing slashes router directive set."
      assert_equal exp, err.message

      invalid_val = ['', 1234, Class.new, Factory.string].sample
      app, router = build_value_app_router(invalid_val)

      err = assert_raises(ArgumentError){ @middleware_class.new(app, router) }
      exp = "TrailingSlashes middleware is in use but there is an invalid "\
            "(`#{invalid_val.inspect}`) trailing slashes router directive set."
      assert_equal exp, err.message
    end

    private

    def build_value_app_router(value)
      router = Deas::Router.new
      router.instance_eval{ @trailing_slashes = value }
      [Factory.sinatra_call, router]
    end

  end

  class HandlerSetupTests < UnitTests
    setup do
      @no_slash_path = Factory.url
      @slash_path    = @no_slash_path+Deas::Router::SLASH

      @app  = Factory.sinatra_call
      @proc = proc{ @app.call(@env) }
    end
  end

  class RemoveHandlerTests < HandlerSetupTests
    desc "RemoveHandler"
    subject{ RemoveHandler }

    should have_readers :run

    should "return the apps response if the path info does not end in a slash" do
      @env['PATH_INFO'] = @no_slash_path

      status, headers, body = subject.run(@env, &@proc)
      assert_equal @app.response.status,  status
      assert_equal @app.response.headers, headers
      assert_equal [@app.response.body],  body
    end

    should "redirect without a trailing slash if the path info ends in a slash" do
      @env['PATH_INFO'] = @slash_path

      status, headers, body = subject.run(@env, &@proc)
      exp = { 'Location' => @no_slash_path }
      assert_equal exp,  headers
      assert_equal 302,  status
      assert_equal [''], body
    end

  end

  class AllowHandlerTests < HandlerSetupTests
    desc "AllowHandler"
    subject{ AllowHandler }

    should have_readers :run

    should "return the apps response if no Deas::NotFound error" do
      paths = [@no_slash_path, @slash_path].shuffle
      @env['PATH_INFO'] = paths.first

      status, headers, body = subject.run(@env, &@proc)
      assert_equal @app.response.status,  status
      assert_equal @app.response.headers, headers
      assert_equal [@app.response.body],  body

      # path info not switched and retried b/c there was no Deas::NotFound
      assert_equal paths.first, @env['PATH_INFO']
    end

    should "switch the trailing slash and return the apps response if Deas::NotFound error" do
      paths = [@no_slash_path, @slash_path].shuffle
      @env['PATH_INFO']  = paths.first
      @env['deas.error'] = Deas::NotFound.new

      status, headers, body = subject.run(@env, &@proc)
      assert_equal @app.response.status,  status
      assert_equal @app.response.headers, headers
      assert_equal [@app.response.body],  body

      # path info switched and retried b/c there was no Deas::NotFound
      assert_equal paths.last, @env['PATH_INFO']
    end

  end

end

require 'assert'
require 'deas/test_runner'

require 'rack/test'
require 'deas/runner'
require 'deas/template_source'
require 'test/support/normalized_params_spy'
require 'test/support/view_handlers'

class Deas::TestRunner

  class UnitTests < Assert::Context
    desc "Deas::TestRunner"
    setup do
      @handler_class = TestRunnerViewHandler
      @runner_class = Deas::TestRunner
    end
    subject{ @runner_class }

    should "be a `Runner`" do
      assert subject < Deas::Runner
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @params = { 'value' => '1' }
      @args = {
        :request         => 'a-request',
        :session         => 'a-session',
        :params          => @params,
        :logger          => 'a-logger',
        :router          => 'a-router',
        :template_source => 'a-source'
      }

      @norm_params_spy = Deas::Runner::NormalizedParamsSpy.new
      Assert.stub(NormalizedParams, :new){ |p| @norm_params_spy.new(p) }

      @runner = @runner_class.new(@handler_class, @args)
    end
    subject{ @runner }

    should have_readers :response_value
    should have_imeths :run

    should "raise an invalid error when not passed a view handler" do
      assert_raises(Deas::InvalidServiceHandlerError) do
        @runner_class.new(Class.new)
      end
    end

    should "super its standard args" do
      assert_equal 'a-request', subject.request
      assert_equal 'a-session', subject.session
      assert_equal @params,     subject.params
      assert_equal 'a-logger',  subject.logger
      assert_equal 'a-router',  subject.router
      assert_equal 'a-source',  subject.template_source
    end

    should "call to normalize its params" do
      assert_equal @params, @norm_params_spy.params
      assert_true @norm_params_spy.value_called
    end

    should "write any non-standard args on the handler" do
      runner = @runner_class.new(@handler_class, :custom_value => 42)
      assert_equal 42, runner.handler.custom_value
    end

    should "not have called its service handlers before callbacks" do
      assert_not_true subject.handler.before_called
    end

    should "have called init on its service handler" do
      assert_true subject.handler.init_called
    end

    should "not set a response value on initialize" do
      assert_nil subject.response_value
    end

    should "set its response value to the return value of `run!` on run" do
      assert_nil subject.response_value
      subject.run
      assert_equal subject.handler.run!, subject.response_value
    end

    should "build halt args if halt is called" do
      value = catch(:halt){ subject.halt }
      assert_kind_of HaltArgs, value
      [:body, :headers, :status].each do |meth|
        assert_respond_to meth, value
      end
    end

    should "build redirect args if redirect is called" do
      value = catch(:halt){ subject.redirect '/some/path' }
      assert_kind_of RedirectArgs, value
      [:path, :halt_args].each do |meth|
        assert_respond_to meth, value
      end
      assert_equal '/some/path', value.path
      assert value.redirect?
    end

    should "build content type args if content type is called" do
      value = subject.content_type 'something'
      assert_kind_of ContentTypeArgs, value
      [:value, :opts].each do |meth|
        assert_respond_to meth, value
      end
      assert_equal 'something', value.value

      assert_same value, subject.content_type
    end

    should "build status args if status is called" do
      value = subject.status(432)
      assert_kind_of StatusArgs, value
      assert_respond_to :value, value
      assert_equal 432, value.value

      assert_same value, subject.status
    end

    should "build headers args if headers is called" do
      value = subject.headers(:some => 'thing')
      assert_kind_of HeadersArgs, value
      assert_respond_to :value, value
      exp_val = {:some => 'thing'}
      assert_equal exp_val, value.value

      assert_same value, subject.headers
    end

    should "build send file args if send file is called" do
      path = Factory.path
      args = subject.send_file path

      assert_kind_of SendFileArgs, args
      [:file_path, :options, :block].each do |meth|
        assert_respond_to meth, args
      end
      assert_equal path, args.file_path
    end

  end

  class RenderSetupTests < InitTests
    setup do
      @template_name = Factory.path
      @locals = { Factory.string => Factory.string }
      @source = Deas::TemplateSource.new(Factory.path)
    end

  end

  class SourceRenderTests < RenderSetupTests
    desc "source render method"
    setup do
      @source_render_args = nil
      Assert.stub(@source, :render){ |*args| @source_render_args = args }
    end

    should "render the template, discard its output and build render args" do
      args = subject.source_render(@source, @template_name, @locals)

      exp = [@template_name, subject.handler, @locals]
      assert_equal exp, @source_render_args

      assert_kind_of RenderArgs, args
      [:source, :template_name, :locals].each do |meth|
        assert_respond_to meth, args
      end
      assert_equal @source,        args.source
      assert_equal @template_name, args.template_name
      assert_equal @locals,        args.locals
    end

  end

  class SourcePartialTests < RenderSetupTests
    desc "source partial method"
    setup do
      @source_partial_args = nil
      Assert.stub(@source, :partial){ |*args| @source_partial_args = args }
    end

    should "render the template, discard its output build render args" do
      args = subject.source_partial(@source, @template_name, @locals)

      exp = [@template_name, @locals]
      assert_equal exp, @source_partial_args

      assert_kind_of RenderArgs, args
      [:source, :template_name, :locals].each do |meth|
        assert_respond_to meth, args
      end
      assert_equal @source,        args.source
      assert_equal @template_name, args.template_name
      assert_equal @locals,        args.locals
    end

  end

  class NormalizedParamsTests < UnitTests
    desc "NormalizedParams"
    setup do
      @norm_params_class = Deas::TestRunner::NormalizedParams
    end

    should "be a normalized params subclass" do
      assert @norm_params_class < Deas::Runner::NormalizedParams
    end

    should "not convert Tempfile param values to strings" do
      tempfile = Class.new(::Tempfile){ def initialize; end }.new
      params = normalized({
        'attachment' => { :tempfile => tempfile }
      })
      assert_kind_of ::Tempfile, params['attachment']['tempfile']
    end

    should "not convert File param values to strings" do
      tempfile = File.new(TEST_SUPPORT_ROOT.join('routes.rb'))
      params = normalized({
        'attachment' => { :tempfile => tempfile }
      })
      assert_kind_of ::File, params['attachment']['tempfile']
    end

    should "not convert Rack::Multipart::UploadedFile param values to strings" do
      tempfile = Rack::Multipart::UploadedFile.new(TEST_SUPPORT_ROOT.join('routes.rb'))
      params = normalized({
        'attachment' => { :tempfile => tempfile }
      })
      assert_kind_of Rack::Multipart::UploadedFile, params['attachment']['tempfile']
    end

    should "not convert Rack::Test::UploadedFile param values to strings" do
      tempfile = Rack::Test::UploadedFile.new(TEST_SUPPORT_ROOT.join('routes.rb'))
      params = normalized({
        'attachment' => { :tempfile => tempfile }
      })
      assert_kind_of Rack::Test::UploadedFile, params['attachment']['tempfile']
    end

    private

    def normalized(params)
      @norm_params_class.new(params).value
    end

  end

end

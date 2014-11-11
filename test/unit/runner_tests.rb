require 'assert'
require 'deas/runner'

require 'deas/logger'
require 'deas/router'
require 'test/support/view_handlers'

class Deas::Runner

  class UnitTests < Assert::Context
    desc "Deas::Runner"
    setup do
      @runner_class = Deas::Runner
    end
    subject{ @runner_class }

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @runner = @runner_class.new(EmptyViewHandler)
    end
    subject{ @runner }

    should have_readers :handler_class, :handler
    should have_readers :request, :response, :session
    should have_readers :params, :logger, :router, :template_source
    should have_imeths :halt, :redirect, :content_type, :status, :headers
    should have_imeths :render, :partial, :send_file

    should "know its handler and handler class" do
      assert_equal EmptyViewHandler, subject.handler_class
      assert_instance_of subject.handler_class, subject.handler
    end

    should "default its settings" do
      assert_nil subject.request
      assert_nil subject.response
      assert_nil subject.session
      assert_kind_of ::Hash, subject.params
      assert_kind_of Deas::NullLogger, subject.logger
      assert_kind_of Deas::Router, subject.router
      assert_kind_of Deas::NullTemplateSource, subject.template_source
    end

    should "default its params" do
      runner = @runner_class.new(TestRunnerViewHandler)
      assert_equal ::Hash.new, runner.params
    end

    should "not implement any actions" do
      assert_raises(NotImplementedError){ subject.halt }
      assert_raises(NotImplementedError){ subject.redirect }
      assert_raises(NotImplementedError){ subject.content_type }
      assert_raises(NotImplementedError){ subject.status }
      assert_raises(NotImplementedError){ subject.headers }
      assert_raises(NotImplementedError){ subject.render }
      assert_raises(NotImplementedError){ subject.partial }
      assert_raises(NotImplementedError){ subject.send_file }
    end

  end

  class NormalizedParamsTests < UnitTests
    desc "NormalizedParams"

    should "convert any non-Array or non-Hash values to strings" do
      exp_params = {
        'nil' => '',
        'int' => '42',
        'str' => 'string'
      }
      assert_equal exp_params, normalized({
        'nil' => nil,
        'int' => 42,
        'str' => 'string'
      })
    end

    should "recursively convert array values to strings" do
      exp_params = {
        'array' => ['', '42', 'string']
      }
      assert_equal exp_params, normalized({
        'array' => [nil, 42, 'string']
      })
    end

    should "recursively convert hash values to strings" do
      exp_params = {
        'values' => {
          'nil' => '',
          'int' => '42',
          'str' => 'string'
        }
      }
      assert_equal exp_params, normalized({
        'values' => {
          'nil' => nil,
          'int' => 42,
          'str' => 'string'
        }
      })
    end

    should "convert any non-string hash keys to string keys" do
      exp_params = {
        'nil' => '',
        'vals' => { '42' => 'int', 'str' => 'string' }
      }
      assert_equal exp_params, normalized({
        'nil' => '',
        :vals => { 42 => :int, 'str' => 'string' }
      })
    end

    private

    def normalized(params)
      TestNormalizedParams.new(params).value
    end

    class TestNormalizedParams < Deas::Runner::NormalizedParams
      def file_type?(value); false; end
    end

  end

end

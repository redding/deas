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
    should have_imeths :render, :source_render, :partial, :source_partial
    should have_imeths :send_file

    should "know its handler and handler class" do
      assert_equal EmptyViewHandler, subject.handler_class
      assert_instance_of subject.handler_class, subject.handler
    end

    should "default its settings" do
      assert_nil subject.request
      assert_nil subject.response
      assert_nil subject.session
      assert_equal ::Hash.new, subject.params
      assert_kind_of Deas::NullLogger, subject.logger
      assert_kind_of Deas::Router, subject.router
      assert_kind_of Deas::NullTemplateSource, subject.template_source
    end

    should "not implement its non-rendering actions" do
      assert_raises(NotImplementedError){ subject.halt }
      assert_raises(NotImplementedError){ subject.redirect }
      assert_raises(NotImplementedError){ subject.content_type }
      assert_raises(NotImplementedError){ subject.status }
      assert_raises(NotImplementedError){ subject.headers }
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

  class RenderSetupTests < InitTests
    setup do
      @template_name = Factory.path
      @locals = { Factory.string => Factory.string }
    end

  end

  class RenderTests < RenderSetupTests
    desc "render method"
    setup do
      @render_args = nil
      Assert.stub(@runner.template_source, :render){ |*args| @render_args = args }
    end

    should "call to its template source render method" do
      subject.render(@template_name, @locals)
      exp = [@template_name, subject.handler, @locals]
      assert_equal exp, @render_args

      subject.render(@template_name)
      exp = [@template_name, subject.handler, {}]
      assert_equal exp, @render_args
    end

  end

  class SourceRenderTests < RenderSetupTests
    desc "source render method"
    setup do
      @source_render_args = nil
      @source = Deas::TemplateSource.new(Factory.path)
      Assert.stub(@source, :render){ |*args| @source_render_args = args }
    end

    should "call to the given source's render method" do
      subject.source_render(@source, @template_name, @locals)
      exp = [@template_name, subject.handler, @locals]
      assert_equal exp, @source_render_args

      subject.source_render(@source, @template_name)
      exp = [@template_name, subject.handler, {}]
      assert_equal exp, @source_render_args
    end

  end

  class PartialTests < RenderSetupTests
    desc "partial method"
    setup do
      @partial_args = nil
      Assert.stub(@runner.template_source, :partial){ |*args| @partial_args = args }
    end

    should "call to its template source partial method" do
      subject.partial(@template_name, @locals)
      exp = [@template_name, @locals]
      assert_equal exp, @partial_args

      subject.partial(@template_name)
      exp = [@template_name, {}]
      assert_equal exp, @partial_args
    end

  end

  class SourcePartialTests < RenderSetupTests
    desc "source partial method"
    setup do
      @source_partial_args = nil
      @source = Deas::TemplateSource.new(Factory.path)
      Assert.stub(@source, :partial){ |*args| @source_partial_args = args }
    end

    should "call to the given source's partial method" do
      subject.source_partial(@source, @template_name, @locals)
      exp = [@template_name, @locals]
      assert_equal exp, @source_partial_args

      subject.source_partial(@source, @template_name)
      exp = [@template_name, {}]
      assert_equal exp, @source_partial_args
    end

  end

end

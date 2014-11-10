require 'assert'
require 'deas/template_source'

require 'deas/template_engine'

class Deas::TemplateSource

  class UnitTests < Assert::Context
    desc "Deas::TemplateSource"
    subject{ Deas::TemplateSource }

    should "disallow certain engine extensions" do
      exp = [ 'rb' ]
      assert_equal exp, subject::DISALLOWED_ENGINE_EXTS
    end

  end

  class InitTests < Assert::Context
    setup do
      @source_path = ROOT.join('test/support').to_s
      @source = Deas::TemplateSource.new(@source_path)
    end
    subject{ @source }

    should have_readers :path, :engines
    should have_imeths :engine, :render, :partial

    should "know its path" do
      assert_equal @source_path.to_s, subject.path
    end

  end

  class EngineRegistrationTests < InitTests
    desc "when registering an engine"
    setup do
      @test_engine = TestEngine
    end

    should "allow registering new engines" do
      assert_kind_of Deas::NullTemplateEngine, subject.engines['test']
      subject.engine 'test', @test_engine
      assert_kind_of @test_engine, subject.engines['test']
    end

    should "register with the source path as a default option" do
      subject.engine 'test', @test_engine
      exp_opts = { 'source_path' => subject.path }
      assert_equal exp_opts, subject.engines['test'].opts

      subject.engine 'test', @test_engine, 'an' => 'opt'
      exp_opts = {
        'source_path' => subject.path,
        'an' => 'opt'
      }
      assert_equal exp_opts, subject.engines['test'].opts

      subject.engine 'test', @test_engine, 'source_path' => 'something'
      exp_opts = { 'source_path' => 'something' }
      assert_equal exp_opts, subject.engines['test'].opts
    end

    should "complain if registering a disallowed temp" do
      assert_kind_of Deas::NullTemplateEngine, subject.engines['rb']
      assert_raises DisallowedEngineExtError do
        subject.engine 'rb', @test_engine
      end
      assert_kind_of Deas::NullTemplateEngine, subject.engines['rb']
    end

  end

  class RenderTests < InitTests
    desc "when rendering a template"
    setup do
      @source.engine('test', TestEngine)
      @source.engine('json', JsonEngine)
    end

    should "call `render` on the configured engine" do
      result = subject.render('test_template', TestServiceHandler, {})
      assert_equal 'render-test-engine', result
    end

    should "only try rendering template files its has engines for" do
      # there should be 2 files called "template" in `test/support` with diff
      # extensions
      result = subject.render('template', TestServiceHandler, {})
      assert_equal 'render-json-engine', result
    end

    should "use the null template engine when an engine can't be found" do
      assert_raises(ArgumentError) do
        subject.render(Factory.string, TestServiceHandler, {})
      end
    end

  end

  class PartialTests < RenderTests
    desc "using `partial`"

    should "call `partial` on the configured engine" do
      result = subject.partial('test_template', TestServiceHandler, {})
      assert_equal 'partial-test-engine', result
    end

    should "only try rendering template files its has engines for" do
      # there should be 2 files called "template" in `test/support` with diff
      # extensions
      result = subject.partial('template', TestServiceHandler, {})
      assert_equal 'partial-json-engine', result
    end

    should "use the null template engine when an engine can't be found" do
      assert_raises(ArgumentError) do
        subject.partial(Factory.string, TestServiceHandler, {})
      end
    end

  end

  class NullTemplateSourceTests < Assert::Context
    desc "Deas::NullTemplateSource"
    setup do
      @source = Deas::NullTemplateSource.new
    end
    subject{ @source }

    should "be a template source" do
      assert_kind_of Deas::TemplateSource, subject
    end

    should "have an empty path string" do
      assert_equal '', subject.path
    end

  end

  class TestEngine < Deas::TemplateEngine
    def render(path, view_handler, locals)
      'render-test-engine'
    end
    def partial(path, view_handler, locals)
      'partial-test-engine'
    end
  end

  class JsonEngine < Deas::TemplateEngine
    def render(path, view_handler, locals)
      'render-json-engine'
    end
    def partial(path, view_handler, locals)
      'partial-json-engine'
    end
  end

  TestServiceHandler = Class.new

end
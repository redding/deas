require 'assert'
require 'deas/template_engine'

require 'pathname'
require 'deas/logger'
require 'test/support/factory'

class Deas::TemplateEngine

  class UnitTests < Assert::Context
    desc "Deas::TemplateEngine"
    setup do
      @source_path = Factory.path
      @template_name = Factory.path
      @view_handler = 'a-view-handler'
      @locals = {}
      @content = Proc.new{}
      @engine = Deas::TemplateEngine.new('some' => 'opts')
    end
    subject{ @engine }

    should have_readers :source_path, :logger, :opts
    should have_imeths :render, :partial, :capture_partial

    should "default its source path" do
      assert_equal Pathname.new(nil.to_s), subject.source_path
    end

    should "allow custom source paths" do
      engine = Deas::TemplateEngine.new('source_path' => @source_path)
      assert_equal Pathname.new(@source_path.to_s), engine.source_path
    end

    should "default its logger" do
      assert_instance_of Deas::NullLogger, subject.logger
    end

    should "allow custom source loggers" do
      logger = 'a-logger'
      engine = Deas::TemplateEngine.new('logger' => logger)
      assert_equal logger, engine.logger
    end

    should "default the opts if none given" do
      exp_opts = {}
      assert_equal exp_opts, Deas::TemplateEngine.new.opts
    end

    should "allow custom opts" do
      exp_opts = {'some' => 'opts'}
      assert_equal exp_opts, subject.opts
    end

    should "raise NotImplementedError on `render`" do
      assert_raises NotImplementedError do
        subject.render(@template_name, @view_handler, @locals)
      end
    end

    should "raise NotImplementedError on `partial`" do
      assert_raises NotImplementedError do
        subject.partial(@template_name, @locals)
      end
    end

    should "raise NotImplementedError on `capture_partial`" do
      assert_raises NotImplementedError do
        subject.capture_partial(@template_name, @locals, &@content)
      end
    end

  end

  class NullTemplateEngineTests < Assert::Context
    desc "Deas::NullTemplateEngine"
    setup do
      @v = 'a-view-handler'
      @l = {}
      @c = Proc.new{}
      @engine = Deas::NullTemplateEngine.new('source_path' => ROOT.to_s)
    end
    subject{ @engine }

    should "be a TemplateEngine" do
      assert_kind_of Deas::TemplateEngine, subject
    end

    should "read and return the given path in its source path on `render`" do
      exists_file = 'test/support/template.json'
      exp = File.read(subject.source_path.join(exists_file).to_s)
      assert_equal exp, subject.render(exists_file, @v, @l)
    end

    should "call `render` to implement its `partial` method" do
      exists_file = 'test/support/template.json'
      exp = subject.render(exists_file, nil, @l)
      assert_equal exp, subject.partial(exists_file, @l)
    end

    should "call `render` to implement its `capture_partial` method" do
      exists_file = 'test/support/template.json'
      exp = subject.render(exists_file, nil, @l)
      assert_equal exp, subject.capture_partial(exists_file, @l, &@c)
    end

    should "complain if given a path that does not exist in its source path" do
      no_exists_file = '/does/not/exists'
      assert_raises ArgumentError do
        subject.render(no_exists_file, @v, @l)
      end
      assert_raises ArgumentError do
        subject.partial(no_exists_file, @l)
      end
      assert_raises ArgumentError do
        subject.capture_partial(no_exists_file, @l, &@c)
      end
    end

  end

end

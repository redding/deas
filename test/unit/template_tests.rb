require 'assert'
require 'deas/template'
require 'test/support/fake_app'

class Deas::Template

  class BaseTests < Assert::Context
    desc "Deas::Template"
    setup do
      @fake_sinatra_call = FakeApp.new
      @template = Deas::Template.new(@fake_sinatra_call, 'users/index')
    end
    subject{ @template }

    should have_instance_methods :name, :options, :render

    should "symbolize it's name" do
      assert_equal :"users/index", subject.name
    end

    should "set it's scope option to a empty Module" do
      assert_instance_of Deas::Template::RenderScope, subject.options[:scope]
    end

    should "call the sinatra_call's `erb` method with #render" do
      return_value = subject.render

      assert_equal subject.name,    return_value[0]
      assert_equal subject.options, return_value[1]
    end

  end

  class RenderScopeTests < Assert::Context
    desc "Deas::Template::RenderScope"
    setup do
      @fake_sinatra_call = FakeApp.new
      @render_scope = Deas::Template::RenderScope.new(@fake_sinatra_call)
    end
    subject{ @render_scope }

    should "call the sinatra_call's erb method with #partial" do
      return_value = subject.partial('part', :something => true)

      assert_equal :_part, return_value[0]

      expected_options = return_value[1]
      assert_instance_of Deas::Template::RenderScope, expected_options[:scope]

      expected_locals = { :something => true }
      assert_equal(expected_locals, expected_options[:locals])
    end

  end

end

class Deas::Partial

  class BaseTests < Assert::Context
    desc "Deas::Partial"
    setup do
      @fake_sinatra_call = FakeApp.new
      @partial = Deas::Partial.new(@fake_sinatra_call, 'users/index/listing', {
        :user => 'Joe Test'
      })
    end
    subject{ @partial }

    should "be a kind of Deas::Template" do
      assert_kind_of Deas::Template, subject
    end

    should "add an underscore to it's template's basename" do
      assert_equal :"users/index/_listing", subject.name
    end

    should "set it's locals option" do
      assert_equal({ :user => 'Joe Test' }, subject.options[:locals])
    end

  end

end

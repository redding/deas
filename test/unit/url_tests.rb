require 'assert'
require 'deas/url'

require 'test/support/view_handlers'

class Deas::Url

  class UnitTests < Assert::Context
    desc "Deas::Url"
    setup do
      @url = Deas::Url.new(:get_info, '/info')
    end
    subject{ @url }

    should have_readers :name, :path
    should have_imeth :path_for

    should "know its name and path info" do
      assert_equal :get_info, subject.name
      assert_equal '/info', subject.path
    end

  end

  class PathForTests < UnitTests
    desc "when generating paths"
    setup do
      @url = Deas::Url.new(:some_thing, '/:some/:thing/*/*')
    end

    should "generate given named params only" do
      exp_path = "/a/goose/*/*"
      assert_equal exp_path, subject.path_for({
        'some' => 'a',
        :thing => 'goose'
      })

      exp_path = "/a/goose/cooked-well/*"
      assert_equal exp_path, subject.path_for({
        'some' => 'a',
        :thing => 'goose',
        :splat => ['cooked-well']
      })

      exp_path = "/a/goose/cooked/well"
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => ['cooked', 'well']
      })
    end

    should "append other (additional) params as query params" do
      exp_path = "/a/goose/cooked/well?aye=a%20a%20a&bee=b"
      assert_equal exp_path, subject.path_for({
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => ['cooked', 'well'],
        'bee'   => 'b',
        :aye    => 'a a a'
      })
    end

    should "generate given ordered params only" do
      exp_path = "/a/:thing/*/*"
      assert_equal exp_path, subject.path_for('a')

      exp_path = "/a/goose/*/*"
      assert_equal exp_path, subject.path_for('a', 'goose')

      exp_path = "/a/goose/cooked-well/*"
      assert_equal exp_path, subject.path_for('a', 'goose', 'cooked-well')

      exp_path = "/a/goose/cooked/well"
      assert_equal exp_path, subject.path_for('a', 'goose', 'cooked', 'well')
    end

    should "generate given mixed ordered and named params" do
      exp_path = "/:some/:thing/*/*"
      assert_equal exp_path, subject.path_for

      exp_path = "/a/goose/*/*"
      assert_equal exp_path, subject.path_for('a', 'thing' => 'goose')

      exp_path = "/goose/a/well/*"
      assert_equal exp_path, subject.path_for('a', 'well', 'some' => 'goose')

      exp_path = "/a/goose/cooked/well"
      assert_equal exp_path, subject.path_for('ignore', 'these', 'params', {
        'some'  => 'a',
        :thing  => 'goose',
        'splat' => ['cooked', 'well']
      })
    end

    should "'squash' duplicate forward-slashes" do
      exp_path = "/a/goose/cooked/well/"
      assert_equal exp_path, subject.path_for({
        'some'  => '/a',
        :thing  => '/goose',
        'splat' => ['///cooked', 'well//']
      })
    end

    should "not alter the given params" do
      params = {'some' => 'thing'}
      exp_params = params.dup

      subject.path_for(params)
      assert_equal exp_params, params
    end

  end

end

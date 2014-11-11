require 'assert'
require 'deas/sinatra_runner'

require 'deas/deas_runner'
require 'deas/template'
require 'test/support/fake_sinatra_call'
require 'test/support/view_handlers'

class Deas::SinatraRunner

  class UnitTests < Assert::Context
    desc "Deas::SinatraRunner"
    setup do
      @runner_class = Deas::SinatraRunner
    end
    subject{ @runner_class }

    should "be a `DeasRunner`" do
      assert subject < Deas::Runner
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @fake_sinatra_call = FakeSinatraCall.new
      @runner = @runner_class.new(DeasRunnerViewHandler, {
        :sinatra_call => @fake_sinatra_call
      })
    end
    subject{ @runner }

    should have_imeths :run

    should "call the sinatra_call's halt with" do
      return_value = catch(:halt){ subject.halt('test') }
      assert_equal [ 'test' ], return_value
    end

    should "call the sinatra_call's redirect method with" do
      return_value = catch(:halt){ subject.redirect('http://google.com') }
      expected = [ 302, { 'Location' => 'http://google.com' } ]

      assert_equal expected, return_value
    end

    should "call the sinatra_call's content_type method using the default_charset" do
      expected = @fake_sinatra_call.content_type('text/plain', :charset => 'utf-8')
      assert_equal expected, subject.content_type('text/plain')

      expected = @fake_sinatra_call.content_type('text/plain', :charset => 'latin1')
      assert_equal expected, subject.content_type('text/plain', :charset => 'latin1')
    end

    should "call the sinatra_call's status to set the response status" do
      assert_equal [422], subject.status(422)
    end

    should "call the sinatra_call's headers to set the response headers" do
      exp_headers = {
        'a-header' => 'some value',
        'other'    => 'other'
      }
      assert_equal [exp_headers], subject.headers(exp_headers)
    end

    should "render the template with :view/:logger locals and the handler layouts" do
      exp_handler = DeasRunnerViewHandler.new(subject)
      exp_layouts = DeasRunnerViewHandler.layouts
      exp_result = Deas::Template.new(@fake_sinatra_call, 'index', {
        :locals => {
          :view => exp_handler,
          :logger => @runner.logger
        },
        :layout => exp_layouts
      }).render
      assert_equal exp_result, subject.render('index')

      exp_result = Deas::Template.new(@fake_sinatra_call, 'index', {
        :locals => {
          :view => 'a-view',
          :some => 'thing',
          :logger => @runner.logger
        },
        :layout => false
      }).render
      assert_equal exp_result, subject.render('index', {
        :layout => false,
        :locals => {
          :view => 'a-view',
          :some => 'thing'
        }
      })
    end

    should "render partials with locals" do
      exp_result = Deas::Template::Partial.new(@fake_sinatra_call, 'info', {
        :some => 'locals'
      }).render

      assert_equal exp_result, subject.partial('info', :some => 'locals')
    end

    should "call the sinatra_call's send_file to set the send files" do
      block_called = false
      args = subject.send_file('a/file', {:some => 'opts'}, &proc{ block_called = true })
      assert_equal 'a/file', args.file_path
      assert_equal({:some => 'opts'}, args.options)
      assert_true block_called
    end

  end

  class InitWithEngineTests < UnitTests
    desc "when init with a template source and matching engine"
    setup do
      @fake_sinatra_call = FakeSinatraCall.new
      @runner = @runner_class.new(DeasRunnerViewHandler, {
        :sinatra_call => @fake_sinatra_call,
        :template_source => FakeTemplateSource.new
      })
    end
    subject{ @runner }

    should "render templates using the source" do
      exp_handler = DeasRunnerViewHandler.new(subject)
      exp_locals = {
        :view => exp_handler,
        :logger => @runner.logger,
        :some => 'locals'
      }
      exp = ['render', 'info', @runner.handler, exp_locals]
      assert_equal exp, subject.render('info', :locals => {
        :some => 'locals'
      })
    end

    should "render partials using the source" do
      exp = ['partial', 'info', { :some => 'locals' }]
      assert_equal exp, subject.partial('info', { :some => 'locals' })
    end

  end

  class FakeTemplateSource
    def engine_for?(template_name)
      true
    end

    def render(*args);  ['render',  *args]; end
    def partial(*args); ['partial', *args]; end
  end

end

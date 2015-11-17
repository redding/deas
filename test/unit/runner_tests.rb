require 'assert'
require 'deas/runner'

require 'rack/utils'
require 'deas/logger'
require 'deas/router'
require 'deas/template_source'
require 'test/support/view_handlers'

class Deas::Runner

  class UnitTests < Assert::Context
    desc "Deas::Runner"
    setup do
      @runner_class = Deas::Runner
    end
    subject{ @runner_class }

    should "know its default mime type" do
      assert_equal 'application/octet-stream', subject::DEFAULT_MIME_TYPE
    end

    should "know its default charset" do
      assert_equal 'utf-8', subject::DEFAULT_CHARSET
    end

    should "know its default status" do
      assert_equal 200, subject::DEFAULT_STATUS
    end

    should "know its default body" do
      assert_equal [], subject::DEFAULT_BODY
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @request = Factory.request
      @runner  = @runner_class.new(EmptyViewHandler, :request => @request)
    end
    subject{ @runner }

    should have_readers :handler_class, :handler
    should have_readers :logger, :router, :template_source
    should have_readers :request, :session, :params
    should have_imeths :to_rack, :run
    should have_imeths :status, :headers, :body, :content_type
    should have_imeths :halt, :redirect, :send_file
    should have_imeths :render, :source_render, :partial, :source_partial

    should "know its handler and handler class" do
      assert_equal EmptyViewHandler, subject.handler_class
      assert_instance_of subject.handler_class, subject.handler
    end

    should "default its attrs" do
      runner = @runner_class.new(EmptyViewHandler)
      assert_kind_of Deas::NullLogger,         runner.logger
      assert_kind_of Deas::Router,             runner.router
      assert_kind_of Deas::NullTemplateSource, runner.template_source

      assert_nil runner.request
      assert_nil runner.session

      assert_equal({}, runner.params)
    end

    should "know its attrs" do
      args = {
        :logger          => 'a-logger',
        :router          => 'a-router',
        :template_source => 'a-source',
        :request         => 'a-request',
        :session         => 'a-session',
        :params          => {}
      }

      runner = @runner_class.new(EmptyViewHandler, args)

      assert_equal args[:logger],          runner.logger
      assert_equal args[:router],          runner.router
      assert_equal args[:template_source], runner.template_source
      assert_equal args[:request],         runner.request
      assert_equal args[:session],         runner.session
      assert_equal args[:params],          runner.params
    end

    should "not implement its run method" do
      assert_raises(NotImplementedError){ subject.run }
    end

    should "know its `to_rack` representation" do
      exp = [
        subject.class::DEFAULT_STATUS,
        subject.headers.to_hash,
        subject.class::DEFAULT_BODY
      ]
      assert_equal exp, subject.to_rack

      status = Factory.integer
      Assert.stub(subject, :status){ status }

      headers = { Factory.string => Factory.string }
      Assert.stub(subject, :headers){ headers }

      body = [Factory.string]
      Assert.stub(subject, :body){ body }

      exp = [status, headers, body]
      assert_equal exp, subject.to_rack
    end

    should "know and set its response status" do
      assert_nil subject.status

      exp = Factory.integer
      subject.status exp
      assert_equal exp, subject.status
    end

    should "know and merge values on its response headers" do
      assert_kind_of Rack::Utils::HeaderHash, subject.headers
      assert_equal({}, subject.headers)

      new_header_values = { Factory.string => Factory.string }
      subject.headers(new_header_values)
      assert_kind_of Rack::Utils::HeaderHash, subject.headers
      assert_equal new_header_values, subject.headers

      location = Factory.string
      subject.headers['Location'] = location
      exp = new_header_values.merge('Location' => location)
      assert_equal exp, subject.headers
    end

    should "know and set its response body" do
      assert_nil subject.body

      exp = Factory.string
      subject.body exp
      assert_equal exp, subject.body

      assert_raises(ArgumentError) do
        subject.body Factory.integer
      end
    end

    should "know and set its response content type header" do
      extname = ".#{Factory.string}"

      subject.content_type(extname) # unknown mime type extname
      exp = subject.class::DEFAULT_MIME_TYPE
      assert_equal exp, subject.headers['Content-Type']

      mime_type = "#{Factory.string}/#{Factory.string}"
      Assert.stub(Rack::Mime, :mime_type).with(
        extname,
        subject.class::DEFAULT_MIME_TYPE
      ){ mime_type }
      subject.content_type(extname) # known mime type extname
      assert_equal mime_type, subject.headers['Content-Type']

      params = {
        Factory.string => Factory.string,
        Factory.string => Factory.string
      }
      subject.content_type(extname, params)
      exp = "#{mime_type};#{params.map{ |k,v| k + '=' + v }.join(',')}"
      assert_equal exp, subject.headers['Content-Type']
    end

  end

  class HaltTests < InitTests
    desc "the `halt` method"
    setup do
      @status  = Factory.integer
      @headers = { Factory.string => Factory.string }
      @body    = [Factory.string]
    end

    should "set response attrs and halt execution" do
      runner = runner_halted_with()
      assert_nil runner.status
      assert_equal({}, runner.headers)
      assert_nil runner.body

      runner = runner_halted_with(@status)
      assert_equal @status, runner.status
      assert_equal({},      runner.headers)
      assert_nil runner.body

      runner = runner_halted_with(@headers)
      assert_nil runner.status
      assert_equal @headers, runner.headers
      assert_nil runner.body

      runner = runner_halted_with(@body)
      assert_nil runner.status
      assert_equal({},    runner.headers)
      assert_equal @body, runner.body

      runner = runner_halted_with(@status, @headers)
      assert_equal @status,  runner.status
      assert_equal @headers, runner.headers
      assert_nil runner.body

      runner = runner_halted_with(@status, @body)
      assert_equal @status, runner.status
      assert_equal({},      runner.headers)
      assert_equal @body,   runner.body

      runner = runner_halted_with(@headers, @body)
      assert_nil runner.status
      assert_equal @headers, runner.headers
      assert_equal @body,    runner.body

      runner = runner_halted_with(@status, @headers, @body)
      assert_equal @status,  runner.status
      assert_equal @headers, runner.headers
      assert_equal @body,    runner.body
    end

    private

    def runner_halted_with(*halt_args)
      @runner_class.new(EmptyViewHandler).tap do |runner|
        catch(:halt){ runner.halt(*halt_args) }
      end
    end

  end

  class HaltCalledWithTests < InitTests
    setup do
      @halt_called_with = nil
      Assert.stub(@runner, :halt){ |*args| @halt_called_with = args; throw :halt }
    end

  end

  class RedirectTests < HaltCalledWithTests
    desc "the `redirect` method"
    setup do
      @location = Factory.boolean ? Factory.string : "/#{Factory.string}"
    end

    should "set response attrs and halt execution" do
      catch(:halt){ subject.redirect(@location) }

      assert_equal 302, subject.status

      exp = get_absolute_url(@location)
      assert_equal exp, subject.headers['Location']

      assert_nil subject.body
      assert_equal [], @halt_called_with
    end

    should "set response attrs and halt execution if called with halt args" do
      halt_args = Factory.integer(3).times.map{ Factory.string }
      catch(:halt){ subject.redirect(@location, *halt_args) }

      assert_equal 302, subject.status

      exp = get_absolute_url(@location)
      assert_equal exp, subject.headers['Location']

      assert_nil subject.body
      assert_equal halt_args, @halt_called_with
    end

    private

    def get_absolute_url(url)
      File.join("#{@request.env['rack.url_scheme']}://#{@request.env['HTTP_HOST']}", url)
    end

  end

  class SendFileSetupTests < HaltCalledWithTests
    desc "the `send_file` method"

  end

  class NotFoundSendFileTests < SendFileSetupTests
    desc "called with a file path that doesn't exist"
    setup do
      @not_found_path = Factory.path
    end

    should "halt 404" do
      catch(:halt){ subject.send_file(@not_found_path) }
      assert_equal [404, []], @halt_called_with
    end

  end

  class ExistingFileSendFileTests < SendFileSetupTests
    setup do
      @file_path = TEST_SUPPORT_ROOT.join('file1.txt')
      @path_name = Pathname.new(@file_path)
    end

  end

  class NotModifiedSendFileTests < ExistingFileSendFileTests
    desc "called with a file path that isn't modified"
    setup do
      @request.env['HTTP_IF_MODIFIED_SINCE'] = @path_name.mtime.httpdate.to_s
    end

    should "halt 304" do
      catch(:halt){ subject.send_file(@file_path) }
      assert_equal [304, []], @halt_called_with
    end

  end

  class ModifiedSendFileTests < ExistingFileSendFileTests
    desc "called with a modified file path"
    setup do
      path_name          = @path_name
      @file_content_type = @runner.instance_eval{ get_content_type(path_name.extname) }
      @send_file_body    = SendFileBody.new(@request.env, @path_name)
    end

    should "halt 200 with the proper headers and body" do
      catch(:halt){ subject.send_file(@file_path) }

      assert_equal [],  @halt_called_with
      assert_equal 200, subject.status

      exp = {
        'Last-Modified'  => @path_name.mtime.httpdate.to_s,
        'Content-Type'   => @file_content_type,
        'Content-Length' => @send_file_body.size.to_s
      }
      assert_equal exp, subject.headers

      assert_equal @send_file_body, subject.body
    end

    should "only update the content type header if it is not already set" do
      custom_content_type = Factory.string
      subject.headers['Content-Type'] = custom_content_type

      catch(:halt){ subject.send_file(@file_path) }
      assert_equal custom_content_type, subject.headers['Content-Type']
    end

    should "only update the content length header if it is not already set" do
      custom_content_length = Factory.integer.to_s
      subject.headers['Content-Length'] = custom_content_length

      catch(:halt){ subject.send_file(@file_path) }
      assert_equal custom_content_length, subject.headers['Content-Length']
    end

    should "halt with the proper header if the `:disposition` option is given" do
      disposition = Factory.string
      catch(:halt){ subject.send_file(@file_path, :disposition => disposition) }

      exp = "#{disposition};filename=\"#{@path_name.basename}\""
      assert_equal exp, subject.headers['Content-Disposition']
    end

    should "halt with the proper header if the `:filename` option is given" do
      filename = Factory.string
      catch(:halt){ subject.send_file(@file_path, :filename => filename) }

      exp = "attachment;filename=\"#{filename}\""
      assert_equal exp, subject.headers['Content-Disposition']
    end

    should "halt with the proper header if the `:disposition` and `:filename` options are given" do
      disposition = Factory.string
      filename    = Factory.string
      catch(:halt) do
        subject.send_file(@file_path, {
          :disposition => disposition,
          :filename    => filename
        })
      end

      exp = "#{disposition};filename=\"#{filename}\""
      assert_equal exp, subject.headers['Content-Disposition']
    end

    should "only update the content dispostion header if it is not already set" do
      custom_disposition = Factory.string
      subject.headers['Content-Disposition'] = custom_disposition

      catch(:halt) do
        subject.send_file(@file_path, {
          :disposition => Factory.string,
          :filename    => Factory.string
        })
      end
      assert_equal custom_disposition, subject.headers['Content-Disposition']
    end

  end

  class PartialSendFileTests < ModifiedSendFileTests
    desc "for a partial response"
    setup do
      Assert.stub(@send_file_body, :partial?){ true }
      @content_range = Factory.string
      Assert.stub(@send_file_body, :content_range){ @content_range }
      Assert.stub(SendFileBody, :new){ @send_file_body }
    end

    should "halt 206 with the proper headers and body for partial requests" do
      catch(:halt){ subject.send_file(@file_path) }

      assert_equal [],              @halt_called_with
      assert_equal 206,             subject.status
      assert_equal @content_range,  subject.headers['Content-Range']
      assert_equal @send_file_body, subject.body
    end

    should "only update the content range header if it is not already set" do
      custom_range = Factory.string
      subject.headers['Content-Range'] = custom_range

      catch(:halt){ subject.send_file(@file_path) }
      assert_equal custom_range, subject.headers['Content-Range']
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
      @source_render_called_with = nil
      Assert.stub(@runner, :source_render){ |*args| @source_render_called_with = args }
    end

    should "call to its `source_render` method with its template source" do
      subject.render(@template_name, @locals)
      exp = [subject.template_source, @template_name, @locals]
      assert_equal exp, @source_render_called_with

      subject.render(@template_name)
      exp = [subject.template_source, @template_name, nil]
      assert_equal exp, @source_render_called_with
    end

  end

  class SourceRenderTests < RenderSetupTests
    desc "source render method"
    setup do
      body = @body = Factory.text
      @render_called_with = nil
      @source = Deas::TemplateSource.new(Factory.path)
      Assert.stub(@source, :render){ |*args| @render_called_with = args; body }
    end

    should "call to the given source's render method and set the return value as the body" do
      subject.source_render(@source, @template_name, @locals)

      exp = [@template_name, subject.handler, @locals]
      assert_equal exp, @render_called_with

      template_name = @template_name
      exp = subject.instance_eval do
        get_content_type(File.extname(template_name), 'charset' => DEFAULT_CHARSET)
      end
      assert_equal exp, subject.headers['Content-Type']

      assert_equal @body, subject.body
    end

    should "default the locals if none given" do
      subject.source_render(@source, @template_name)
      exp = [@template_name, subject.handler, {}]
      assert_equal exp, @render_called_with
    end

    should "only update the content type header if it is not already set" do
      custom_content_type = Factory.string
      subject.headers['Content-Type'] = custom_content_type

      subject.source_render(@source, @template_name, @locals)
      assert_equal custom_content_type, subject.headers['Content-Type']
    end

  end

  class PartialTests < RenderSetupTests
    desc "partial method"
    setup do
      @source_partial_called_with = nil
      Assert.stub(@runner, :source_partial){ |*args| @source_partial_called_with = args }
    end

    should "call to its `source_partial` method with its template source" do
      subject.partial(@template_name, @locals)
      exp = [subject.template_source, @template_name, @locals]
      assert_equal exp, @source_partial_called_with

      subject.partial(@template_name)
      exp = [subject.template_source, @template_name, nil]
      assert_equal exp, @source_partial_called_with
    end

  end

  class SourcePartialTests < RenderSetupTests
    desc "source partial method"
    setup do
      @partial_called_with = nil
      @source = Deas::TemplateSource.new(Factory.path)
      Assert.stub(@source, :partial){ |*args| @partial_called_with = args }
    end

    should "call to the given source's partial method" do
      subject.source_partial(@source, @template_name, @locals)
      exp = [@template_name, @locals]
      assert_equal exp, @partial_called_with
    end

    should "default the locals if none given" do
      subject.source_partial(@source, @template_name)
      exp = [@template_name, {}]
      assert_equal exp, @partial_called_with
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

  class SendFileBodyTests < UnitTests
    desc "SendFileBody"
    setup do
      @env       = Factory.request.env
      @path_name = Pathname.new(TEST_SUPPORT_ROOT.join('file1.txt'))

      @body = SendFileBody.new(@env, @path_name)
    end
    subject{ @body }

    should have_readers :path_name, :size, :content_range
    should have_imeths :partial?, :range_begin, :range_end
    should have_imeths :each

    should "know its chunk size" do
      assert_equal 8192, SendFileBody::CHUNK_SIZE
    end

    should "know its path name" do
      assert_equal @path_name, subject.path_name
    end

    should "know if it is equal to another body" do
      same_path_same_range = SendFileBody.new(@env, @path_name)
      Assert.stub(same_path_same_range, :range_begin){ subject.range_begin }
      Assert.stub(same_path_same_range, :range_end){ subject.range_end }
      assert_equal same_path_same_range, subject

      other_path = Pathname.new(TEST_SUPPORT_ROOT.join('file2.txt'))
      other_path_same_range = SendFileBody.new(@env, other_path)
      Assert.stub(other_path_same_range, :range_begin){ subject.range_begin }
      Assert.stub(other_path_same_range, :range_end){ subject.range_end }
      assert_not_equal other_path_same_range, subject

      same_path_other_range = SendFileBody.new(@env, @path_name)

      Assert.stub(same_path_other_range, :range_begin){ Factory.integer }
      Assert.stub(same_path_other_range, :range_end){ subject.range_end }
      assert_not_equal same_path_other_range, subject

      Assert.stub(same_path_other_range, :range_begin){ subject.range_begin }
      Assert.stub(same_path_other_range, :range_end){ Factory.integer }
      assert_not_equal same_path_other_range, subject
    end

  end

  class SendFileBodyIOTests < SendFileBodyTests
    setup do
      @min_num_chunks = 3
      @num_chunks     = @min_num_chunks + Factory.integer(3)
      @path_name      = Pathname.new(TEST_SUPPORT_ROOT.join('file3.txt'))

      @path_name.open('w') do |io|
        io.write('a' * (@num_chunks * SendFileBody::CHUNK_SIZE))
      end
    end
    teardown do
      @path_name.delete
    end

  end

  class NonPartialSendFileBodyTests < SendFileBodyIOTests
    desc "for non/multi/invalid partial content requests"
    setup do
      range = [nil, 'bytes=', 'bytes=0-1,2-3', 'bytes=3-2', 'bytes=abc'].choice
      env = range.nil? ? {} : { 'HTTP_RANGE' => range }
      @body = SendFileBody.new(env, @path_name)
    end

    should "not be partial" do
      assert_false subject.partial?
    end

    should "be the full content size" do
      assert_equal @path_name.size, subject.size
    end

    should "have no content range" do
      assert_nil subject.content_range
    end

    should "have the full content size as its range" do
      assert_equal 0,              subject.range_begin
      assert_equal subject.size-1, subject.range_end
    end

    should "chunk the full content when iterated" do
      chunks = []
      subject.each{ |chunk| chunks << chunk }

      assert_equal @num_chunks,               chunks.size
      assert_equal subject.class::CHUNK_SIZE, chunks.first.size
      assert_equal @path_name.read,           chunks.join('')
    end

  end

  class PartialSendFileBodyTests < SendFileBodyIOTests
    desc "for a partial content request"
    setup do
      @start_chunk    = Factory.boolean ? 0 : 1
      @partial_begin  = @start_chunk * SendFileBody::CHUNK_SIZE
      @partial_chunks = @num_chunks - Factory.integer(@min_num_chunks)
      @partial_size   = @partial_chunks * SendFileBody::CHUNK_SIZE
      @partial_end    = @partial_begin + (@partial_size-1)

      env = { 'HTTP_RANGE' => "bytes=#{@partial_begin}-#{@partial_end}" }
      @body = SendFileBody.new(env, @path_name)
    end
    subject{ @body }

    should "be partial" do
      assert_true subject.partial?
    end

    should "be the specified partial size" do
      assert_equal @partial_size, subject.size
    end

    should "know its content range" do
      exp = "bytes #{@partial_begin}-#{@partial_end}/#{@path_name.size}"
      assert_equal exp, subject.content_range
    end

    should "know its range" do
      assert_equal @partial_begin, subject.range_begin
      assert_equal @partial_end,   subject.range_end
    end

    should "chunk the range when iterated" do
      chunks = []
      subject.each{ |chunk| chunks << chunk }

      assert_equal @partial_chunks,           chunks.size
      assert_equal subject.class::CHUNK_SIZE, chunks.first.size

      exp = @path_name.read[@partial_begin..@partial_end]
      assert_equal exp, chunks.join('')
    end

  end

end

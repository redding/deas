require 'ostruct'
require 'deas/logger'
require 'deas/router'
require 'deas/template_source'

class FakeSinatraCall

  # Mimic's the context that is accessible in a Sinatra' route. Should provide
  # any methods needed to replace using an actual Sinatra app.

  attr_accessor :request, :response, :params, :logger, :router, :session
  attr_accessor :settings

  def initialize(settings = {})
    @request         = FakeRequest.new('GET','/something', {}, OpenStruct.new)
    @response        = FakeResponse.new
    @session         = @request.session
    @params          = @request.params
    @logger          = Deas::NullLogger.new
    @router          = Deas::Router.new
    @template_source = Deas::NullTemplateSource.new

    @settings = OpenStruct.new({
      :deas_template_scope => Deas::Template::Scope,
      :deas_default_charset => 'utf-8',
      :logger => @logger,
      :router => @router,
      :template_source => @template_source
    }.merge(settings))
  end

  def halt(*args)
    throw :halt, args
  end

  def redirect(*args)
    halt 302, { 'Location' => args[0] }
  end

  def content_type(*args); args; end
  def status(*args);       args; end
  def headers(*args);      args; end

  # return the template name for each nested calls
  def erb(template_name, opts, &block)
    if block
      RenderArgs.new(template_name, opts, block.call)
    else
      RenderArgs.new(template_name, opts, nil)
    end
  end
  RenderArgs = Struct.new(:template_name, :opts, :block_call_result)

  def send_file(file_path, opts, &block)
    if block
      SendFileArgs.new(file_path, opts, block.call)
    else
      SendFileArgs.new(file_path, opts, nil)
    end
  end
  SendFileArgs = Struct.new(:file_path, :options, :block_call_result)

end

class FakeRequest < Struct.new(:http_method, :path, :params, :session)
  alias :request_method :http_method

  attr_reader :logging_msgs

  def env
    @env ||= {
      'deas.logging' => Proc.new do |msg|
        @logging_msgs ||= []
        @logging_msgs.push(msg)
      end
    }
  end
end
FakeResponse = Struct.new(:status, :headers, :body)

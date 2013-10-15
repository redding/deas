require 'deas'
require 'ostruct'

class FakeSinatraCall

  # Mimic's the context that is accessible in a Sinatra' route. Should provide
  # any methods needed to replace using an actual Sinatra app.

  attr_accessor :request, :response, :params, :settings, :session, :logger

  def initialize(settings={})
    @request = FakeRequest.new('GET','/something', {}, OpenStruct.new)
    @params   = @request.params
    @session  = @request.session
    @response = FakeResponse.new
    @logger   = Deas::NullLogger.new
    @settings = OpenStruct.new(settings.merge({
      :deas_template_scope => Deas::Template::Scope,
      :deas_default_charset => 'utf-8'
    }))
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

  RenderArgs = Struct.new(:template_name, :opts, :block_call_result)

  def erb(template_name, opts, &block)
    if block
      RenderArgs.new(template_name, opts, block.call)
    else
      RenderArgs.new(template_name, opts, nil)
    end
  end

end

class FakeRequest < Struct.new(:http_method, :path, :params, :session)
  alias :request_method :http_method
end
FakeResponse = Struct.new(:status, :headers, :body)

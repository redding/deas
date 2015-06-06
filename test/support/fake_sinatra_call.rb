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

    @content_type = nil
    @status       = 200
    @headers      = {}

    @settings = OpenStruct.new({
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

  def content_type(*args)
    return @content_type if args.empty?
    opts, value = [
      args.last.kind_of?(Hash) ? args.pop : {},
      args.last
    ]
    opts_value = opts.keys.map{ |k| "#{k}=#{opts[k]}" }.join(';')
    @content_type = [value, opts_value].reject{ |v| v.to_s.empty? }.join(';')
  end

  def status(*args)
    return @status if args.empty?
    @status = args.last
  end

  def headers(*args)
    return @headers if args.empty?
    @headers = args.last
  end

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

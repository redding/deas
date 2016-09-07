require 'ostruct'

class FakeRequest < Struct.new(:http_method, :path, :params, :session, :env)

  alias :request_method :http_method

  attr_reader :logging_msgs

  def initialize(args = nil)
    args ||= {}
    super(*[
      args[:http_method] || 'GET',
      args[:path]        || Factory.path,
      args[:params]      || {},
      args[:session]     || OpenStruct.new,
      args[:env]         || {}
    ])

    self.env.merge!({
      'rack.url_scheme' => Factory.boolean ? 'http' : 'https',
      'HTTP_HOST'       => "#{Factory.string}.#{Factory.string}",

      'deas.logging' => Proc.new do |msg|
        @logging_msgs ||= []
        @logging_msgs.push(msg)
      end
    })
  end

end

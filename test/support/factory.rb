require 'assert/factory'
require 'deas/logger'
require 'deas/request_data'
require 'deas/router'
require 'deas/server_data'
require 'deas/template_source'
require 'test/support/fake_request'
require 'test/support/fake_response'
require 'test/support/fake_sinatra_call'

module Factory
  extend Assert::Factory

  def self.exception(klass = nil, message = nil)
    klass ||= StandardError
    message ||= Factory.text
    exception = nil
    begin; raise(klass, message); rescue klass => exception; end
    exception.set_backtrace(nil) if Factory.boolean
    exception
  end

  def self.server_data(opts = nil)
    Deas::ServerData.new({
      :logger          => Deas::NullLogger.new,
      :router          => Deas::Router.new,
      :template_source => Deas::NullTemplateSource.new
    }.merge(opts || {}))
  end

  def self.request(args = nil)
    FakeRequest.new(args)
  end

  def self.response(args = nil)
    FakeResponse.new(args)
  end

  def self.request_data(args = nil)
    args ||= {}
    Deas::RequestData.new({
      :request    => args[:request]    || Factory.request,
      :response   => args[:response]   || Factory.response,
      :params     => args[:params]     || { Factory.string => Factory.string },
      :route_path => args[:route_path] || Factory.string
    })
  end

  def self.sinatra_call(settings = nil)
    FakeSinatraCall.new(settings)
  end

end

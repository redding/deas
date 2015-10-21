require 'assert/factory'
require 'deas/logger'
require 'deas/router'
require 'deas/server_data'
require 'deas/template_source'
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

  def self.sinatra_call(settings = nil)
    FakeSinatraCall.new(settings)
  end

end

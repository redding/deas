require 'deas/runner'
require 'deas/template'

module Deas

  class SinatraRunner < Runner

    def self.run(*args)
      self.new(*args).run
    end

    def initialize(handler_class, sinatra_call)
      @sinatra_call  = sinatra_call
      @app_settings  = @sinatra_call.settings
      @logger        = @sinatra_call.settings.logger
      @params        = @sinatra_call.params
      @request       = @sinatra_call.request
      @response      = @sinatra_call.response
      @session       = @sinatra_call.session
      super(handler_class)
    end

    def run
      run_callbacks @handler_class.before_callbacks
      @handler.init
      response_data = @handler.run
      run_callbacks @handler_class.after_callbacks
      response_data
    end

    # Helpers

    def halt(*args)
      @sinatra_call.halt(*args)
    end

    def redirect(*args)
      @sinatra_call.redirect(*args)
    end

    def content_type(value, opts=nil)
      @sinatra_call.content_type(value, {
        :charset => @sinatra_call.settings.deas_default_charset
      }.merge(opts || {}))
    end

    def render(template_name, options = nil, &block)
      options ||= {}
      options[:locals] = { :view => @handler }.merge(options[:locals] || {})
      options[:layout] ||= @handler_class.layouts
      Deas::Template.new(@sinatra_call, template_name, options).render(&block)
    end

    private

    def run_callbacks(callbacks)
      callbacks.each{|proc| @handler.instance_eval(&proc) }
    end

  end
end

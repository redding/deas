require 'deas/runner'

module Deas

  class SinatraRunner < Runner

    def self.run(*args)
      self.new(*args).run
    end

    def initialize(handler_class, sinatra_call)
      @sinatra_call = sinatra_call
      @logger       = @sinatra_call.settings.deas_logger
      @params       = @sinatra_call.params
      @request      = @sinatra_call.request
      @response     = @sinatra_call.response

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

    # TODO expand this
    def render(template_name, options = nil)
      options ||= {}
      options[:locals] = { :view => @handler }.merge(options[:locals] || {})
      @sinatra_call.erb(template_name.to_sym, options)
    end

    # TODO implement these
    # redirect
    # redirect_to
    # session

    private

    def run_callbacks(callbacks)
      callbacks.each{|proc| @handler.instance_eval(&proc) }
    end

  end

end

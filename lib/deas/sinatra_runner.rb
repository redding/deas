require 'deas/runner'
require 'deas/template'

module Deas

  class SinatraRunner < Runner

    def self.run(*args)
      self.new(*args).run
    end

    attr_reader :app_settings

    def initialize(handler_class, sinatra_call)
      @sinatra_call  = sinatra_call
      @app_settings  = @sinatra_call.settings

      @request       = @sinatra_call.request
      @response      = @sinatra_call.response
      @params        = normalize_params(@sinatra_call.params)
      @logger        = @sinatra_call.settings.logger
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

    def content_type(*args)
      return @sinatra_call.content_type if args.empty?

      opts, value = [
        args.last.kind_of?(::Hash) ? args.pop : {},
        args.first
      ]
      @sinatra_call.content_type(value, {
        :charset => @sinatra_call.settings.deas_default_charset
      }.merge(opts || {}))
    end

    def status(*args)
      @sinatra_call.status(*args)
    end

    def headers(*args)
      @sinatra_call.headers(*args)
    end

    def render(template_name, options = nil, &block)
      options ||= {}
      options[:locals] = { :view => @handler }.merge(options[:locals] || {})
      options[:layout] ||= @handler_class.layouts

      self.content_type(get_content_type(template_name)) if self.content_type.nil?
      Deas::Template.new(@sinatra_call, template_name, options).render(&block)
    end

    def partial(partial_name, locals = nil)
      Deas::Template::Partial.new(@sinatra_call, partial_name, locals).render
    end

    def send_file(*args, &block)
      @sinatra_call.send_file(*args, &block)
    end

    private

    def run_callbacks(callbacks)
      callbacks.each{|proc| @handler.instance_eval(&proc) }
    end

    def get_content_type(template_name)
      File.extname(template_name)[1..-1] || 'html'
    end

    def normalize_params(params)
      StringifiedKeys.new(params)
    end

    module StringifiedKeys
      def self.new(value)
        if value.is_a?(::Array)
          value.map{ |i| StringifiedKeys.new(i) }
        elsif Rack::Utils.params_hash_type?(value)
          value.inject({}){ |h, (k, v)| h[k.to_s] = StringifiedKeys.new(v); h }
        else
          value
        end
      end
    end

  end
end

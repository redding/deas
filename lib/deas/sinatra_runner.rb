require 'deas/deas_runner'
require 'deas/template'

module Deas

  class SinatraRunner < DeasRunner

    def initialize(handler_class, args = nil)
      @sinatra_call = (args || {})[:sinatra_call]
      super(handler_class, args)
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
      options[:locals] = {
        :view => @handler,
        :logger => @logger
      }.merge(options[:locals] || {})
      options[:layout] ||= @handler_class.layouts

      self.content_type(get_content_type(template_name)) if self.content_type.nil?
      Deas::Template.new(@sinatra_call, template_name, options).render(&block)
    end

    def send_file(*args, &block)
      @sinatra_call.send_file(*args, &block)
    end

    private

    def get_content_type(template_name)
      File.extname(template_name)[1..-1] || 'html'
    end

  end
end

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

    def render(template_name, opts = nil, &block)
      self.content_type(get_content_type(template_name)) if self.content_type.nil?

      # TODO: move to DeasRunner, don't pass sinatra call to create template
      # def render(template_name, *args, &block)
      #   super(template_name, *args, &block)
      options = opts || {}
      options[:locals] = {
        :view => self.handler,
        :logger => self.logger
      }.merge(options[:locals] || {})
      options[:layout] = self.handler_class.layouts if !options.key?(:layout)
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

require 'deas/deas_runner'

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
      @sinatra_call.content_type(*args)
    end

    def status(*args)
      @sinatra_call.status(*args)
    end

    def headers(*args)
      @sinatra_call.headers(*args)
    end

    def source_render(source, template_name, locals = nil)
      if self.content_type.nil?
        self.content_type(get_content_type_ext(template_name) || 'html')
      end
      super
    end

    def send_file(file_path, opts = nil, &block)
      if self.content_type.nil?
        self.content_type(get_content_type_ext(file_path))
      end
      @sinatra_call.send_file(file_path, opts || {}, &block)
    end

    private

    def get_content_type_ext(file_path)
      File.extname(file_path)[1..-1]
    end

  end
end

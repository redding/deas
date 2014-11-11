require 'pathname'
require 'deas/logger'

module Deas

  class TemplateEngine

    attr_reader :source_path, :logger, :opts

    def initialize(opts = nil)
      @opts = opts || {}
      @source_path = Pathname.new(@opts['source_path'].to_s)
      @logger = @opts['logger'] || Deas::NullLogger.new
    end

    def render(template_name, view_handler, locals)
      raise NotImplementedError
    end

    def partial(template_name, view_handler, locals)
      raise NotImplementedError
    end

    def capture_render(template_name, view_handler, locals, &content)
      raise NotImplementedError
    end

    def capture_partial(template_name, view_handler, locals, &content)
      raise NotImplementedError
    end

  end

  class NullTemplateEngine < TemplateEngine

    def render(template_name, view_handler, locals)
      template_file = self.source_path.join(template_name).to_s
      unless File.exists?(template_file)
        raise ArgumentError, "template file `#{template_file}` does not exist"
      end
      File.read(template_file)
    end

    alias_method :capture_render,  :render
    alias_method :partial,         :render
    alias_method :capture_partial, :render

  end

end
